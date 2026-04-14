# Fabrizio Donati

Engineering leader and quantitative modeler focused on real-time C++/Python systems, high-performance computing, mathematical modeling, nonlinear optimization, and production-grade research infrastructure.

My background spans Formula 1 simulation, biomedical modeling, and performance-critical engineering. The repositories here cover market data, backtesting, pricing, market microstructure, and related tooling.

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

## Repository Structure

```text
market-data-toolkit  ->  backtest-lab
       |                     |
       |                     -> strategy evaluation, portfolio simulation, reporting
       -> historical data ingestion, normalization, feature generation

options-pricer       -> standalone numerical finance / derivatives library
lob-engine           -> standalone C++ systems / market microstructure project
```

- `market-data-toolkit` handles ingestion, normalization, and feature generation for historical datasets
- `backtest-lab` consumes normalized datasets for deterministic strategy evaluation
- `options-pricer` is a standalone numerical library for option pricing and diagnostics
- `lob-engine` is a standalone C++ project for order-book matching and workload measurement

## Run The Full Showcase

There is now a single orchestration entrypoint in this repo:

```bash
./showcase/run_showcase.sh
```

It generates a fixture-driven portfolio demo across the repos and writes the consolidated output to:

```text
showcase/output/index.md
```

The run produces:

- market-data ingestion, validation, and feature outputs
- document-ingestion and event-extraction outputs
- backtest metrics, curves, and chart outputs
- pricing comparison, sweep, and Monte Carlo diagnostics outputs
- order-book replay and benchmark outputs

The orchestration layer is thin by design. The individual repos remain independent; this entrypoint runs a consistent fixture-driven demo across them.

## Core Strengths

- Real-time C++ / Python engineering with deterministic and performance-aware design
- High-performance computing, nonlinear optimization, numerical methods, and inference
- Research-to-production workflows: prototyping, validation, profiling, and hardening
- Data pipelines, signal engineering, and reproducible evaluation

## Focus Areas

Current focus areas:

- quantitative research infrastructure
- high-performance and low-latency systems
- simulation, nonlinear optimization, and model validation
- market microstructure, pricing, and data-driven decision support
