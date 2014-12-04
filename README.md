nim-MCTS
========

Monte Carlo tree search with Upper Confidence bounds for Trees (UCT) for Nim

UCT searches for good moves, in a random way. Every iteration has three stages:

1. Walk down the tree of tried moves, in upper confidence (UCT) order, until an untried move is found.

2. When an untried move is found, play the game by randomly playing moves.

3. When the game is finished, walk back up the tree, updating the upper confidence (UCT).

This algorithm will explore untried moves first, then moves that look promising for whichever player
is choosing the move.

UCT is evaluated as wins/visits + UCTK\*sqrt(2\*log(visits)/visits)

UCTK is some constant, which will tune exploration vs exploitation. A higher constant will tend to
favor more exploration (approaching infinity, it will pick the least visited node), while a zero value will
simply pick the current best node.

I also added an option to run a heuristic search. TODO - read the literature, and find a good way to do this.

Using a very simple heuristic, I get a player using 5 search iterations to beat one using 1000 iterations in Othello.
Which is a pretty good speedup.

Another speedup would be Zobrist hashing. This basically hashes seen nodes (since many games have multiple paths to
the same state). Zobrist hashing using XORing of positions, so the entire hash need not be recalculated every move
(when you move a piece, you XOR it out of its current position, then XOR it into the next position).

To run Othello:

   nimrod compile --run -d:release --p:../ Othello.nim

