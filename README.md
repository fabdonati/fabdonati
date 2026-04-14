# Fabrizio Donati

Engineering leader and quantitative modeler focused on real-time C++/Python systems, high-performance computing, mathematical modeling, nonlinear optimization, and production-grade research infrastructure.

My background spans Formula 1 simulation, biomedical modeling, and performance-critical engineering. The repositories here are a focused public portfolio around market data, backtesting, pricing, and systems-oriented tooling.

## What I Work On

- Real-time and performance-critical C++ / Python systems
- High-performance computing, mathematical modeling, and nonlinear optimization
- Research infrastructure for data, signals, and reproducible evaluation
- Quantitative finance projects focused on market data, backtesting, pricing, and microstructure

## Selected Projects

- [`market-data-toolkit`](https://github.com/fabdonati/market-data-toolkit): ingest, normalize, and enrich OHLCV-style market data with a typed Python API and CLI
- [`backtest-lab`](https://github.com/fabdonati/backtest-lab): compact backtesting engine for daily strategies, metrics, and text-based reports
- [`options-pricer`](https://github.com/fabdonati/options-pricer): Black-Scholes, Greeks, implied volatility, and Monte Carlo comparisons for vanilla options
- [`lob-engine`](https://github.com/fabdonati/lob-engine): C++20 price-time-priority limit order book with tests, replay support, and benchmark tooling

## How The Repos Fit Together

```text
market-data-toolkit  ->  backtest-lab
       |                     |
       |                     -> strategy evaluation, portfolio simulation, reporting
       -> historical data ingestion, normalization, feature generation

options-pricer       -> standalone numerical finance / derivatives library
lob-engine           -> standalone C++ systems / market microstructure project
```

- `market-data-toolkit` is the data foundation
- `backtest-lab` is the research engine built to consume normalized datasets
- `options-pricer` is intentionally independent and focused on quantitative pricing logic
- `lob-engine` is intentionally independent and focused on matching-engine correctness and performance

## Run The Full Showcase

There is now a single orchestration entrypoint in this repo:

```bash
./showcase/run_showcase.sh
```

It generates a fixture-driven portfolio demo across the repos and writes the consolidated output to:

```text
showcase/output/index.md
```

That run produces:

- market-data ingestion, validation, and feature artifacts
- document-intelligence extraction artifacts
- backtest metrics, curves, and chart artifacts
- pricing comparison, sweep, and Monte Carlo diagnostics artifacts
- order-book replay and benchmark artifacts

The orchestration layer is intentionally thin. The repos stay modular; this entrypoint just turns them into one inspectable narrative.

Planned next layers:

- `ibkr-live-feed`: live broker connectivity, streaming normalization, replay, and monitoring
- `market-intel-pipeline`: structured event extraction from news, filings, and transcripts

## Core Strengths

- Real-time C++ / Python engineering with deterministic and performance-aware design
- High-performance computing, nonlinear optimization, numerical methods, and inference
- Research-to-production workflows: prototyping, validation, profiling, and hardening
- Data pipelines, signal engineering, and reproducible evaluation

## Current Direction

I'm especially interested in the intersection of:

- quantitative research infrastructure
- high-performance and low-latency systems
- simulation, nonlinear optimization, and model validation
- market microstructure, pricing, and data-driven decision support

## Notes

Most of the repositories here are small by design. The goal is to keep them readable, well-scoped, and easy to evaluate quickly while still showing real engineering depth.
