% SPDX-License-Identifier: AGPL-3.0-only
% Uncertified — research prototype, not for operational use.
% Copyright (C) 2026 AHMAD ALI PARR / SnapKitty Research Lab

function varargout = alphazero_transformer_recreation(command, varargin)
% ALPHAZERO_TRANSFORMER_RECREATION
% Clean-room MATLAB reference core for an AlphaZero-style Go agent using a
% modern token/tensor Transformer policy-value network.
%
% This is an original educational scaffold, not DeepMind source code and not
% a drop-in replacement for Leela Zero, ELF OpenGo, MiniGo, or PhoenixGo.
% It implements tensor layout, Transformer forward pass, masked policy/value
% heads, PUCT selection/update primitives, and self-play target construction.
% A complete engine still needs a verified Go rules implementation, batched
% inference, replay storage, gradient training, checkpointing, and evaluation.
%
% Commands:
%   P = alphazero_transformer_recreation('init', cfg)
%   [policy,value,cache] = alphazero_transformer_recreation('forward', P, board, toPlay)
%   idx = alphazero_transformer_recreation('puct', N, W, Pprior, cPuct)
%   [pi,z] = alphazero_transformer_recreation('targets', visitCounts, temperature, outcome)
%   cfg = alphazero_transformer_recreation('config')
%
% Board encoding: board is N-by-N with +1 for black, -1 for white, 0 empty.
% toPlay is +1 (black) or -1 (white). Policy indexes are linear MATLAB
% indexes 1..N^2, with N^2+1 reserved for pass.

if nargin == 0, command = 'config'; end
switch lower(command)
    case 'config'
        varargout{1} = defaultConfig();
    case 'init'
        cfg = defaultConfig();
        if ~isempty(varargin), cfg = mergeConfig(cfg, varargin{1}); end
        varargout{1} = initializeParameters(cfg);
    case 'forward'
        P = varargin{1}; board = varargin{2}; toPlay = varargin{3};
        [policy,value,cache] = forwardNetwork(P,board,toPlay);
        if nargout <= 1
            varargout{1} = struct('policy',policy,'value',value,'cache',cache);
        else
            varargout{1} = policy;
            if nargout >= 2, varargout{2} = value; end
            if nargout >= 3, varargout{3} = cache; end
        end
    case 'puct'
        N = varargin{1}; W = varargin{2}; Pprior = varargin{3}; cPuct = varargin{4};
        varargout{1} = puctSelect(N,W,Pprior,cPuct);
    case 'targets'
        visits = varargin{1}; temperature = varargin{2}; outcome = varargin{3};
        [pi,z] = makeTargets(visits,temperature,outcome);
        varargout{1} = struct('policyTarget',pi,'valueTarget',z);
    otherwise
        error('Unknown command: %s', command);
end
end

function cfg = defaultConfig()
cfg = struct();
cfg.boardSize = 9;             % Start small; 19x19 is substantially more expensive.
cfg.dModel = 128;
cfg.nHeads = 4;
cfg.nBlocks = 4;
cfg.dFF = 256;
cfg.nPlanes = 8;               % board feature planes
cfg.dropout = 0.0;              % deterministic baseline; add training dropout explicitly
cfg.layerNormEps = 1e-5;
cfg.seed = 20261012;
cfg.cPuct = 1.5;
cfg.dirichletAlpha = 0.03;
cfg.dirichletFraction = 0.25;
cfg.resignThreshold = -0.95;
cfg.maxMovesFactor = 2;
end

function cfg = mergeConfig(cfg, userCfg)
if ~isstruct(userCfg), error('cfg must be a struct'); end
names = fieldnames(userCfg);
for k=1:numel(names)
    if ~isfield(cfg,names{k}), error('Unknown config field: %s', names{k}); end
    cfg.(names{k}) = userCfg.(names{k});
end
assert(cfg.boardSize >= 2 && cfg.boardSize <= 19 && cfg.boardSize == floor(cfg.boardSize));
assert(mod(cfg.dModel,cfg.nHeads)==0,'dModel must divide evenly by nHeads');
end

function P = initializeParameters(cfg)
rng(cfg.seed,'twister');
d = cfg.dModel; f = cfg.dFF; h = cfg.nHeads; n = cfg.boardSize^2+1;
P.cfg = cfg;
P.token.W = randn(cfg.nPlanes,d,'single') * sqrt(2/(cfg.nPlanes+d));
P.token.b = zeros(1,d,'single');
% Absolute 2-D board position embeddings plus one pass-token embedding.
P.pos = randn(n,d,'single') * 0.02;
P.side.W = randn(1,d,'single') * 0.02;
for b=1:cfg.nBlocks
    q = struct();
    q.ln1g = ones(1,d,'single'); q.ln1b = zeros(1,d,'single');
    q.Wq = randn(d,d,'single')/sqrt(d); q.Wk = randn(d,d,'single')/sqrt(d);
    q.Wv = randn(d,d,'single')/sqrt(d); q.Wo = randn(d,d,'single')/sqrt(d);
    q.ln2g = ones(1,d,'single'); q.ln2b = zeros(1,d,'single');
    q.W1 = randn(d,f,'single')*sqrt(2/d); q.b1=zeros(1,f,'single');
    q.W2 = randn(f,d,'single')*sqrt(2/f); q.b2=zeros(1,d,'single');
    P.block(b)=q; %#ok<AGROW>
end
P.policy.W = randn(d,1,'single')/sqrt(d); P.policy.b=single(0);
P.pass.W = randn(d,1,'single')/sqrt(d); P.pass.b=single(0);
P.value.W1 = randn(d,d/2,'single')/sqrt(d); P.value.b1=zeros(1,d/2,'single');
P.value.W2 = randn(d/2,1,'single')/sqrt(d/2); P.value.b2=single(0);
P.metadata = struct('format','AZ-TX-MATLAB-1','createdUTC','2026-10-12', ...
    'sourceKind','clean-room educational implementation','boardSize',cfg.boardSize);
end

function [policy,value,cache] = forwardNetwork(P,board,toPlay)
% Sequence convention: [tokens x features], batch dimension omitted.
cfg=P.cfg; N=cfg.boardSize; d=cfg.dModel;
assert(isequal(size(board),[N N]),'board dimensions must match configured boardSize');
assert(any(toPlay==[-1 1]),'toPlay must be -1 or +1');
Xplanes=encodeBoardPlanes(board,toPlay);
Xflat=reshape(Xplanes,N*N,cfg.nPlanes);
X=[Xflat; zeros(1,cfg.nPlanes,'single')]; % pass token
X=single(X)*P.token.W + P.token.b;
X=X+P.pos(1:N*N+1,:);
X=X+single(toPlay)*P.side.W;
blockCache=cell(cfg.nBlocks,1);
for b=1:cfg.nBlocks
    [X,blockCache{b}]=transformerBlock(X,P.block(b),cfg);
end
% Per-point policy logits; pass has its own token-specific scalar head.
logits=X(1:N*N,:)*P.policy.W+P.policy.b;
passLogit=X(end,:)*P.pass.W+P.pass.b;
logits=[logits;passLogit];
legal=legalMoveMask(board); legal=[legal(:);true];
logits(~legal)=-Inf;
policy=stableSoftmax(logits);
% Value head pools all tokens; scalar is from side-to-play perspective.
pooled=mean(X,1);
h=tanh(pooled*P.value.W1+P.value.b1);
value=tanh(h*P.value.W2+P.value.b2);
cache=struct('planes',Xplanes,'tokens',X,'blocks',{blockCache}, ...
    'logits',logits,'legalMask',legal,'pooled',pooled,'valueHidden',h);
end

function planes=encodeBoardPlanes(board,toPlay)
% Eight planes: own stones, opponent stones, empty, own-to-play constant,
% opponent-to-play constant, liberties proxy, board edge, pass indicator.
N=size(board,1); own=board==toPlay; opp=board==-toPlay; empty=board==0;
edge=false(N); edge(1,:)=true;edge(end,:)=true;edge(:,1)=true;edge(:,end)=true;
lib=zeros(N,'single');
for r=1:N, for c=1:N
    if board(r,c)~=0
        lib(r,c)=single(anyNeighborEmpty(board,r,c));
    end
end,end
planes=cat(3,single(own),single(opp),single(empty), ...
    ones(N,N,'single')*single(toPlay==1),ones(N,N,'single')*single(toPlay==-1), ...
    lib,single(edge),zeros(N,N,'single'));
end

function [Y,cache]=transformerBlock(X,B,cfg)
% Pre-LN encoder block: X + MHA(LN(X)); then X + FFN(LN(X)).
A=layerNorm(X,B.ln1g,B.ln1b,cfg.layerNormEps);
Q=A*B.Wq; K=A*B.Wk; V=A*B.Wv;
T=size(X,1); d=cfg.dModel; dh=d/cfg.nHeads;
M=zeros(T,d,'single');
for head=1:cfg.nHeads
    ix=(head-1)*dh+(1:dh);
    q=Q(:,ix); k=K(:,ix); v=V(:,ix);
    scores=(q*k')/sqrt(single(dh));
    weights=stableSoftmax(scores,2);
    M(:,ix)=weights*v;
end
attn=M*B.Wo;
R=X+attn;
F=layerNorm(R,B.ln2g,B.ln2b,cfg.layerNormEps);
F=max(F*B.W1+B.b1,0)*B.W2+B.b2;
Y=R+F;
cache=struct('input',X,'normalized1',A,'Q',Q,'K',K,'V',V, ...
    'attention',M,'residual1',R,'normalized2',F,'output',Y);
end

function Y=layerNorm(X,g,b,epsVal)
mu=mean(X,2); v=mean((X-mu).^2,2);
Y=((X-mu)./sqrt(v+epsVal)).*g+b;
end

function p=stableSoftmax(x,dim)
if nargin<2, dim=1; end
m=max(x,[],dim); m(~isfinite(m))=0;
y=x-m; y(~isfinite(y))=-Inf;
e=exp(y); e(~isfinite(e))=0; den=sum(e,dim);
p=e./max(den,realmin('single'));
end

function mask=legalMoveMask(board)
% Fast occupancy + local-liberty legality proxy. This does not fully implement
% Go ko/superko or suicide rules; use a tested rules engine for real matches.
N=size(board,1); mask=(board(:)==0);
for k=1:N*N
    if ~mask(k), continue; end
    [r,c]=ind2sub([N N],k);
    % Any adjacent empty point makes the move immediately non-suicidal.
    if anyNeighborEmpty(board,r,c), continue; end
    % Capture-aware local proxy: adjacent opponent group with one liberty.
    nbr=neighbors(N,r,c); canCapture=false;
    for j=1:numel(nbr)
        [rr,cc]=ind2sub([N N],nbr(j));
        if board(rr,cc)~=0 && board(rr,cc)~=board(r,c) && groupHasOneLiberty(board,rr,cc)
            canCapture=true; break;
        end
    end
    mask(k)=canCapture;
end
end

function tf=anyNeighborEmpty(board,r,c)
N=size(board,1); nb=neighbors(N,r,c); tf=false;
for k=1:numel(nb), [rr,cc]=ind2sub([N N],nb(k)); if board(rr,cc)==0,tf=true;return;end,end
end

function tf=groupHasOneLiberty(board,r,c)
N=size(board,1); color=board(r,c); seen=false(N); stack=[r c]; seen(r,c)=true; liberties=false(N); tf=false;
while ~isempty(stack)
    p=stack(end,:);stack(end,:)=[]; nb=neighbors(N,p(1),p(2));
    for k=1:numel(nb)
        [rr,cc]=ind2sub([N N],nb(k));
        if board(rr,cc)==0, liberties(rr,cc)=true;
        elseif board(rr,cc)==color && ~seen(rr,cc),seen(rr,cc)=true;stack(end+1,:)=[rr cc]; %#ok<AGROW>
        end
    end
end
 tf=nnz(liberties)==1;
end

function ix=neighbors(N,r,c)
ix=[];
if r>1,ix(end+1)=sub2ind([N N],r-1,c);end
if r<N,ix(end+1)=sub2ind([N N],r+1,c);end
if c>1,ix(end+1)=sub2ind([N N],r,c-1);end
if c<N,ix(end+1)=sub2ind([N N],r,c+1);end
end

function action=puctSelect(N,W,prior,cPuct)
% PUCT: Q(s,a) + c_puct P(s,a) sqrt(sum_b N(s,b))/(1+N(s,a)).
N=double(N(:)); W=double(W(:)); prior=double(prior(:));
assert(numel(N)==numel(W)&&numel(W)==numel(prior));
q=zeros(size(W)); visited=N>0; q(visited)=W(visited)./N(visited);
score=q+cPuct.*prior.*sqrt(max(1,sum(N)))./(1+N);
[~,action]=max(score);
end

function [pi,z]=makeTargets(visits,temperature,outcome)
% pi is the visit-count policy target; z is terminal outcome in player-to-move
% perspective supplied by caller (+1 win, -1 loss, 0 draw).
visits=max(double(visits(:)),0);
assert(any(visits>0),'At least one visit count must be positive');
assert(isscalar(outcome)&&any(outcome==[-1 0 1]));
if temperature<=1e-8
    [~,ix]=max(visits); pi=zeros(size(visits));pi(ix)=1;
else
    a=visits.^(1/temperature); pi=a/sum(a);
end
pi=single(pi); z=single(outcome);
end

% Reference MCTS node data shape (to be used by a complete search driver):
% node.prior   : [N^2+1 x 1] legal-masked prior from network
% node.visit   : [N^2+1 x 1] edge visit counts N(s,a)
% node.valueSum: [N^2+1 x 1] edge value sums W(s,a)
% node.child   : cell(N^2+1,1), child state after applying each action
% Search loop: select PUCT edge -> apply legal move -> expand with network ->
% backup value with sign flip at every ply. At root, optionally mix Dirichlet
% noise into legal priors; select action from visit counts using temperature.
%
% AlphaZero training target for each self-play position t:
%   pi_t(a) = N(s_t,a)^(1/tau) / sum_b N(s_t,b)^(1/tau)
%   z_t = final game result from perspective of player to move at t
% Loss convention:
%   L = (z-v)^2 - sum_a pi(a)*log(p(a)) + lambda*||theta||^2
% Gradient training is intentionally not faked here. Implement it with
% dlarray/dlfeval/dlgradient and an explicit differentiable forward pass, or
% port the parameterized equations to JAX/another autodiff tensor runtime.
