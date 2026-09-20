# Dream-RSI: Recursive Self-Improvement Exploration

## Project Overview

Dream-RSI (Recursive Self-Improvement) is an Ada 2022 port of the exploration-layer ideas from [Dream-RSI](https://github.com/zhengkid/Dream-RSI) ([dream-rsi.com](https://www.dream-rsi.com)). It models a discovery tree, builds a **replay simulator** from evaluated history, and improves an exploration policy offline ("dreaming") instead of paying for repeated online rollouts.

## Features

- **Recursive Fixed Exploration (RFE):** baseline with a static exploration weight
- **Dream-RSI Exploration:** offline policy search over the replay simulator, then redeploy
- **Tree validation:** rejects backward parents, cycles, and self-loops
- **Contracts:** `Pre` / `Post` / `Global` on the public API

## Build & test

**Prerequisites:** GNAT / gprbuild (Ada 2022)

```bash
make test
```

Flags: `-gnatwa -gnat2022` (zero warnings expected). Clean with `make clean`.

The embedded suite (`tests.adb`) runs **42 assertions across 14 suites** (functional checks, edges, and exception paths).

## License

MIT — see [LICENSE](LICENSE).

## Citation (original paper)

```bibtex
@article{zheng2026dreamrsi,
  title   = {Dream-RSI: Recursive Self-Improvement through Evolving Worlds},
  author  = {Zheng, Tong and Wu, Xidong and Zhang, Zheng and others},
  journal = {arXiv preprint arXiv:2609.14858},
  year    = {2026}
}
```
