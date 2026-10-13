# AlphaZero / AlphaGo Zero → Tensor-Transformer Recreation Source Dump

## Scope and provenance

This bundle is a clean-room MATLAB reference implementation of core AlphaZero-style patterns re-expressed as a token-based Transformer policy/value network. It is **not** DeepMind's original source code and does not copy the full source of other projects. The public projects below are independent implementations and research artifacts; consult each repository's license before incorporating code.

## Public source projects

1. **Leela Zero** — C++ Go engine; neural-network evaluation plus PUCT/MCTS; modeled closely on the AlphaGo Zero paper. It explicitly notes that the repository does not include DeepMind's original weights.  
   https://github.com/leela-zero/leela-zero
2. **ELF OpenGo** — Meta's open reimplementation and training artifacts, including pretrained models, self-play games, and analysis.  
   https://github.com/pytorch/ELF  
   https://ai.meta.com/tools/elf-opengo/
3. **MiniGo** — readable TensorFlow implementation intended to reproduce AlphaGo Zero methods and expose the training pipeline.  
   https://github.com/tensorflow/minigo
4. **PhoenixGo** — Tencent implementation of the AlphaGo Zero paper, with build/run instructions and released trained network files.  
   https://github.com/Tencent/PhoenixGo
5. **Original research paper** — Silver et al., *Mastering the game of Go without human knowledge*, Nature (2017). Supplementary data includes SGF game records, not the full DeepMind engine source.  
   https://www.nature.com/articles/nature24270
6. **Generalized AlphaZero paper** — *Mastering Chess and Shogi by Self-Play with a General Reinforcement Learning Algorithm*.  
   https://arxiv.org/abs/1712.01815

## Pattern map: classical AlphaZero → modern Transformer layout

| AlphaZero pattern | Transformer recreation mapping |
|---|---|
| Board feature planes | One token per board intersection, plus a dedicated pass token |
| Residual convolutional tower | Pre-layer-normalized Transformer encoder blocks |
| Spatial policy head | Shared per-token policy projection, plus a separate pass-token logit |
| Value head | Mean-pool token states, then a scalar tanh head |
| PUCT/MCTS | Kept as a search layer independent of the neural architecture |
| Self-play | Repeated search, sample/select from root visit counts, record states and outcomes |
| Policy target | Normalize visit counts raised to inverse temperature |
| Value target | Final game outcome from the perspective of the player to move |
| Training loss | Value squared error + policy cross-entropy + weight regularization |
| Replay buffer | Store board features, legal-action mask, visit-count target, outcome, model/version metadata |
| Evaluation | Fixed-seed matches, color swaps, win rate and confidence intervals |

## MATLAB file contents

`alphazero_transformer_recreation.m` includes:

- deterministic parameter initialization;
- board-to-token feature encoding;
- multi-head self-attention, pre-LayerNorm, residual paths, and feed-forward blocks;
- per-point policy logits and a pass-action logit;
- a value head;
- PUCT edge selection;
- visit-count policy targets and terminal value targets;
- a deliberately conservative legal-move mask approximation.

### Important limitations

- The file is a **reference core**, not a complete competitive Go engine.
- Its legal-move mask is only a local proxy and does **not** implement full capture application, ko/superko, complete suicide handling, scoring, or game termination. Replace it with a tested Go rules engine before trusting games or training data.
- It provides no fake training implementation: the differentiable gradient/update loop, batching, replay persistence, checkpoint serialization, self-play workers, and tournament harness still need to be added. The intended loss is documented in the source.
- It initializes random weights. It does not contain DeepMind's private weights or claim equivalent strength.
- MATLAB/Octave execution was not verified in this environment because no interpreter was available.

## Run the available core in MATLAB

```matlab
P = alphazero_transformer_recreation('init');
board = zeros(9,9,'single');
[policy,value,cache] = alphazero_transformer_recreation('forward',P,board,1);
[~,action] = max(policy);

% PUCT primitive: arrays are indexed by action, including pass as action N^2+1.
N = zeros(82,1); W = zeros(82,1); prior = policy;
action = alphazero_transformer_recreation('puct',N,W,prior,1.5);

% Training targets from root visit counts and terminal outcome (+1/-1/0).
target = alphazero_transformer_recreation('targets',N+double((1:82)'==action),1,1);
```

## Recommended reconstruction order

1. Replace the legality proxy with a tested Go state-transition module.
2. Add MCTS node expansion, child-state application, value-sign-flipping backup, root noise, and temperature-controlled action selection.
3. Add a differentiable training pass for `L = (z-v)^2 - sum(pi .* log(p)) + lambda*||theta||^2`.
4. Add replay-buffer persistence and deterministic checkpoint metadata.
5. Validate against known SGF records, legal-move invariants, fixed-seed self-play, and color-swapped tournaments.
6. Compare Transformer and residual-convolutional baselines under matched compute and data budgets. A Transformer layout is an architectural adaptation, not the original AlphaGo Zero network.
