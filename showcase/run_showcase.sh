#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FINANCE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/showcase/output"

MARKET_DATA_REPO="${FINANCE_DIR}/market-data-toolkit"
MARKET_INTEL_REPO="${FINANCE_DIR}/market-intel-pipeline"
BACKTEST_REPO="${FINANCE_DIR}/backtest-lab"
OPTIONS_REPO="${FINANCE_DIR}/options-pricer"
LOB_REPO="${FINANCE_DIR}/lob-engine"

MARKET_DATA_PY="${MARKET_DATA_REPO}/.venv/bin/python"
MARKET_INTEL_PY="${MARKET_INTEL_REPO}/.venv/bin/python"
BACKTEST_PY="${BACKTEST_REPO}/.venv/bin/python"
OPTIONS_PY="${OPTIONS_REPO}/.venv/bin/python"

MARKET_DATA_OUT="${OUTPUT_DIR}/market-data-toolkit"
MARKET_INTEL_OUT="${OUTPUT_DIR}/market-intel-pipeline"
BACKTEST_OUT="${OUTPUT_DIR}/backtest-lab"
OPTIONS_OUT="${OUTPUT_DIR}/options-pricer"
LOB_OUT="${OUTPUT_DIR}/lob-engine"

require_executable() {
  local target="$1"
  if [[ ! -x "${target}" ]]; then
    echo "Missing executable: ${target}" >&2
    exit 1
  fi
}

run_and_capture() {
  local output_file="$1"
  shift
  "$@" >"${output_file}" 2>&1
}

has_ollama_runtime() {
  if ! command -v ollama >/dev/null 2>&1; then
    return 1
  fi
  if [[ ! -x "${MARKET_INTEL_PY}" ]]; then
    return 1
  fi
  if ! "${MARKET_INTEL_PY}" -c "import ollama" >/dev/null 2>&1; then
    return 1
  fi
  curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1
}

prepare_output_dirs() {
  rm -rf "${OUTPUT_DIR}"
  mkdir -p \
    "${MARKET_DATA_OUT}" \
    "${MARKET_INTEL_OUT}" \
    "${BACKTEST_OUT}/sleeves" \
    "${OPTIONS_OUT}" \
    "${LOB_OUT}"
}

run_market_data_toolkit() {
  run_and_capture "${MARKET_DATA_OUT}/aapl_ingest.txt" \
    "${MARKET_DATA_PY}" -m market_data_toolkit.cli \
    ibkr-ingest \
    "${MARKET_DATA_REPO}/examples/portfolio_pipeline/aapl_ibkr.csv" \
    --symbol AAPL \
    --output "${MARKET_DATA_OUT}/aapl_normalized.csv"

  run_and_capture "${MARKET_DATA_OUT}/msft_ingest.txt" \
    "${MARKET_DATA_PY}" -m market_data_toolkit.cli \
    ibkr-ingest \
    "${MARKET_DATA_REPO}/examples/portfolio_pipeline/msft_ibkr.csv" \
    --symbol MSFT \
    --output "${MARKET_DATA_OUT}/msft_normalized.csv"

  run_and_capture "${MARKET_DATA_OUT}/combine.txt" \
    "${MARKET_DATA_PY}" -m market_data_toolkit.cli \
    combine \
    "${MARKET_DATA_OUT}/aapl_normalized.csv" \
    "${MARKET_DATA_OUT}/msft_normalized.csv" \
    --output "${MARKET_DATA_OUT}/portfolio.csv"

  run_and_capture "${MARKET_DATA_OUT}/validate.txt" \
    "${MARKET_DATA_PY}" -m market_data_toolkit.cli \
    validate \
    "${MARKET_DATA_OUT}/portfolio.csv"

  run_and_capture "${MARKET_DATA_OUT}/features.txt" \
    "${MARKET_DATA_PY}" -m market_data_toolkit.cli \
    features \
    "${MARKET_DATA_OUT}/portfolio.csv" \
    --output "${MARKET_DATA_OUT}/features.csv"
}

run_market_intel_pipeline() {
  run_and_capture "${MARKET_INTEL_OUT}/ingest.txt" \
    "${MARKET_INTEL_PY}" -m market_intel_pipeline.cli \
    ingest \
    "${MARKET_INTEL_REPO}/examples/headlines" \
    --source-type headline \
    --source-name showcase-headlines \
    --output "${MARKET_INTEL_OUT}/headlines.jsonl"

  run_and_capture "${MARKET_INTEL_OUT}/enrich_mock.txt" \
    "${MARKET_INTEL_PY}" -m market_intel_pipeline.cli \
    enrich \
    "${MARKET_INTEL_OUT}/headlines.jsonl" \
    --backend mock \
    --output "${MARKET_INTEL_OUT}/events_mock.jsonl" \
    --csv-output "${MARKET_INTEL_OUT}/events_mock.csv"

  run_and_capture "${MARKET_INTEL_OUT}/report_mock.txt" \
    "${MARKET_INTEL_PY}" -m market_intel_pipeline.cli \
    report \
    "${MARKET_INTEL_OUT}/events_mock.jsonl" \
    --output "${MARKET_INTEL_OUT}/report_mock.csv"

  if has_ollama_runtime; then
    run_and_capture "${MARKET_INTEL_OUT}/enrich_ollama.txt" \
      "${MARKET_INTEL_PY}" -m market_intel_pipeline.cli \
      enrich \
      "${MARKET_INTEL_OUT}/headlines.jsonl" \
      --backend ollama \
      --model gemma3 \
      --host http://localhost:11434 \
      --output "${MARKET_INTEL_OUT}/events_ollama.jsonl" \
      --csv-output "${MARKET_INTEL_OUT}/events_ollama.csv"

    run_and_capture "${MARKET_INTEL_OUT}/compare_mock_vs_ollama.txt" \
      "${MARKET_INTEL_PY}" -m market_intel_pipeline.cli \
      compare \
      "${MARKET_INTEL_OUT}/headlines.jsonl" \
      --left-backend mock \
      --right-backend ollama \
      --right-model gemma3 \
      --right-host http://localhost:11434 \
      --output "${MARKET_INTEL_OUT}/compare_mock_vs_ollama.csv"
  else
    cat >"${MARKET_INTEL_OUT}/ollama_status.txt" <<'EOF'
Ollama semantic extraction was skipped.

To enable it:
1. Install the optional dependency in market-intel-pipeline:
   python -m pip install -e ".[ollama,dev]"
2. Start Ollama locally:
   ollama serve
3. Pull a model:
   ollama pull gemma3
EOF
  fi
}

run_backtest_lab() {
  run_and_capture "${BACKTEST_OUT}/report.txt" \
    "${BACKTEST_PY}" -m backtest_lab.cli \
    "${MARKET_DATA_OUT}/portfolio.csv" \
    --input-format market-data-toolkit \
    --strategy moving-average \
    --short-window 2 \
    --long-window 3 \
    --weights-file "${BACKTEST_REPO}/examples/market_data_toolkit/weights.csv" \
    --metrics-output "${BACKTEST_OUT}/report_metrics.csv" \
    --equity-output "${BACKTEST_OUT}/equity_curve.csv" \
    --sleeve-output-dir "${BACKTEST_OUT}/sleeves" \
    --comparison-output "${BACKTEST_OUT}/comparison_curve.csv" \
    --chart-output "${BACKTEST_OUT}/equity_chart.png"
}

run_options_pricer() {
  run_and_capture "${OPTIONS_OUT}/compare.txt" \
    "${OPTIONS_PY}" -m options_pricer.cli \
    compare \
    --spot 100 \
    --strike 100 \
    --rate 0.05 \
    --volatility 0.2 \
    --maturity 1 \
    --type call \
    --steps 200 \
    --paths 20000 \
    --seed 42 \
    --report-output "${OPTIONS_OUT}/compare.csv"

  run_and_capture "${OPTIONS_OUT}/sweep.txt" \
    "${OPTIONS_PY}" -m options_pricer.cli \
    sweep \
    --spot 100 \
    --strike 100 \
    --rate 0.05 \
    --volatility 0.2 \
    --maturity 1 \
    --type call \
    --axis volatility \
    --start 0.15 \
    --stop 0.35 \
    --points 5 \
    --steps 200 \
    --paths 20000 \
    --seed 42 \
    --output "${OPTIONS_OUT}/vol_sweep.csv"

  run_and_capture "${OPTIONS_OUT}/mc_report.txt" \
    "${OPTIONS_PY}" -m options_pricer.cli \
    mc-report \
    --spot 100 \
    --strike 100 \
    --rate 0.05 \
    --volatility 0.2 \
    --maturity 1 \
    --type call \
    --path-grid 1000,5000,10000,20000,50000 \
    --seed 42 \
    --report-output "${OPTIONS_OUT}/mc_report.csv" \
    --chart-output "${OPTIONS_OUT}/mc_report.svg"
}

run_lob_engine() {
  if [[ ! -x "${LOB_REPO}/build/order_book_replay" || ! -x "${LOB_REPO}/build/order_book_benchmark" ]]; then
    run_and_capture "${LOB_OUT}/build.txt" \
      cmake -S "${LOB_REPO}" -B "${LOB_REPO}/build"
    run_and_capture "${LOB_OUT}/build_append.txt" \
      cmake --build "${LOB_REPO}/build"
  fi

  run_and_capture "${LOB_OUT}/replay.txt" \
    "${LOB_REPO}/build/order_book_replay" \
    "${LOB_REPO}/examples/basic_lifecycle.txt"

  run_and_capture "${LOB_OUT}/benchmark_resting.txt" \
    "${LOB_REPO}/build/order_book_benchmark" \
    --scenario resting

  run_and_capture "${LOB_OUT}/benchmark_matching.txt" \
    "${LOB_REPO}/build/order_book_benchmark" \
    --scenario matching

  run_and_capture "${LOB_OUT}/benchmark_lifecycle.txt" \
    "${LOB_REPO}/build/order_book_benchmark" \
    --scenario lifecycle
}

write_index() {
  local ollama_links=""
  if [[ -f "${MARKET_INTEL_OUT}/events_ollama.csv" ]]; then
    ollama_links='- Ollama event rows: [events_ollama.csv](market-intel-pipeline/events_ollama.csv)
- Backend comparison: [compare_mock_vs_ollama.csv](market-intel-pipeline/compare_mock_vs_ollama.csv)
- Ollama/backend summary: [compare_mock_vs_ollama.txt](market-intel-pipeline/compare_mock_vs_ollama.txt)'
  else
    ollama_links='- Ollama status: [ollama_status.txt](market-intel-pipeline/ollama_status.txt)'
  fi

  cat >"${OUTPUT_DIR}/index.md" <<EOF
# Portfolio Showcase

Generated from \`fabdonati/showcase/run_showcase.sh\`.

This run stitches the repositories together as one portfolio demonstration:

1. market data ingestion, validation, and feature generation
2. local-document intelligence extraction
3. backtesting on normalized portfolio data
4. numerical pricing, sweeps, and Monte Carlo diagnostics
5. deterministic order-book replay and benchmark workloads

## Data / Research Infrastructure

- Portfolio dataset: [portfolio.csv](market-data-toolkit/portfolio.csv)
- Feature dataset: [features.csv](market-data-toolkit/features.csv)
- Validation summary: [validate.txt](market-data-toolkit/validate.txt)

What it shows:
- raw IBKR-style files normalized into a canonical schema
- portfolio-ready multi-symbol combination
- validation diagnostics for structural data quality
- derived features ready for research workflows

## Market Intelligence

- Normalized documents: [headlines.jsonl](market-intel-pipeline/headlines.jsonl)
- Mock event rows: [events_mock.csv](market-intel-pipeline/events_mock.csv)
- Mock report summary: [report_mock.txt](market-intel-pipeline/report_mock.txt)
${ollama_links}

What it shows:
- typed document ingestion from local text sources
- deterministic extraction baseline
- optional local semantic extraction via Ollama
- backend comparison as an evaluation artifact instead of an anecdotal demo

## Backtesting

- Terminal report: [report.txt](backtest-lab/report.txt)
- Metrics CSV: [report_metrics.csv](backtest-lab/report_metrics.csv)
- Equity curve: [equity_curve.csv](backtest-lab/equity_curve.csv)
- Strategy vs benchmark: [comparison_curve.csv](backtest-lab/comparison_curve.csv)
- Chart: [equity_chart.png](backtest-lab/equity_chart.png)
- Sleeve curves: [sleeves/](backtest-lab/sleeves)

What it shows:
- normalized market data consumed directly from the data toolkit output
- deterministic strategy evaluation
- portfolio-level and symbol-level artifacts for inspection

## Numerical Methods

- Model comparison report: [compare.txt](options-pricer/compare.txt)
- Model comparison CSV: [compare.csv](options-pricer/compare.csv)
- Volatility sweep: [vol_sweep.csv](options-pricer/vol_sweep.csv)
- Monte Carlo diagnostics: [mc_report.txt](options-pricer/mc_report.txt)
- Monte Carlo diagnostics CSV: [mc_report.csv](options-pricer/mc_report.csv)
- Monte Carlo convergence chart: [mc_report.svg](options-pricer/mc_report.svg)

What it shows:
- analytic pricing benchmark
- lattice and Monte Carlo approximations against that benchmark
- sweep-style sensitivity analysis
- explicit uncertainty quantification through standard errors and 95% confidence intervals

## Systems Engineering

- Replay output: [replay.txt](lob-engine/replay.txt)
- Resting-book benchmark: [benchmark_resting.txt](lob-engine/benchmark_resting.txt)
- Matching-heavy benchmark: [benchmark_matching.txt](lob-engine/benchmark_matching.txt)
- Lifecycle benchmark: [benchmark_lifecycle.txt](lob-engine/benchmark_lifecycle.txt)

What it shows:
- deterministic replay for correctness and explainability
- multiple workload shapes for the matching engine
- measurable differences between resting, matching, and lifecycle scenarios

## Run Notes

- This showcase is intentionally fixture-driven and artifact-first.
- The market-intelligence step falls back to the mock backend if Ollama is not available.
- Generated outputs live only under \`showcase/output/\` in this repo.
EOF
}

main() {
  require_executable "${MARKET_DATA_PY}"
  require_executable "${MARKET_INTEL_PY}"
  require_executable "${BACKTEST_PY}"
  require_executable "${OPTIONS_PY}"
  prepare_output_dirs
  run_market_data_toolkit
  run_market_intel_pipeline
  run_backtest_lab
  run_options_pricer
  run_lob_engine
  write_index
  printf 'Showcase complete. Open %s\n' "${OUTPUT_DIR}/index.md"
}

main "$@"
