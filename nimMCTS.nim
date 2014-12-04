# The MIT License (MIT)
#
# Copyright (c) 2014 Peter James Row
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# MPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

##########################################################################################################

# Based on UCT Monte Carlo Tree Search algorithm in Python 2.7.

# Written by Peter Cowling, Ed Powley, Daniel Whitehouse (University of York, UK) September 2012.

# Licence is granted to freely use and distribute for any sensible/legal purpose so long as this comment
# remains in any distributed code.

# For more information about Monte Carlo Tree Search check out our web site at www.mcts.ai


import algorithm
import math

type
  Prediction* = tuple
    result: float
    quality: float

  PNode[M] = ref Node[M]

  Node[M] = tuple
    parentNode: PNode[M]
    move: M
    childNodes: seq[PNode[M]]
    wins: float
    visits: float
    score: float
    untriedMoves: seq[M]
    playerJustMoved: int

  TState* = object of TObject
    playerJustMoved*: int

method GetMoves[M](state:TState):seq[M]=
  quit "to override!"

method Clone(state:TState):TState=
  quit "to override!"

method DoMove[M](state:var TState,move:M)=
  quit "to override!"

method GetResult(state:TState,playerjm:int):float=
  quit "to override!"

method to_string(state:TState):string=
  quit "to override!"

# send the game

proc InitNode[M,T](move: M, parent: PNode[M], state:T):PNode[M]{.inline.} =
    new(result)
    result.move = move # the move that got us to this node - "None" for the root node
    result.parentNode = parent # "None" for the root node
    result.childNodes.newSeq(0)
    result.childNodes.setLen(0)
    result.wins = 0.0
    result.visits = 0.0
    result.score = 0.0
    result.playerJustMoved = state.playerJustMoved # the only part of the state that the Node needs later

proc NodeCmp(x, y: PNode):int =
  result = cmp(x.score,y.score)

proc UCTSelectChild(node: var PNode):PNode{.inline.} =
  let old_len = node.ChildNodes.len
  assert old_len>0
  algorithm.sort(a=node.ChildNodes, cmp=NodeCmp, order = Descending)
  assert old_len==node.ChildNodes.len
  result = node.ChildNodes[0]

proc AddChild[M,T](node: var PNode[M], move:M, s:T):PNode[M]{.inline.} =
  result = InitNode(move = move, parent = node, state=s)
  let i = node.untriedMoves.find(move)
  system.delete(node.untriedMoves,i)
  let n = node.childNodes.len
  node.childNodes.setLen(n+1)
  node.childNodes[n]=result

proc Update[M](node: var Node[M], res, UCTK:float){.inline.} =
  node.visits += 1.0
  node.wins += res
  let wins = node.wins + 1.0
  let visits = node.visits + 2.0
  node.score = wins/visits + UCTK*math.sqrt(2*(math.ln(visits)/visits))

proc UpdateStar[M](node: var Node[M], res, weight, UCTK:float){.inline.} =
  node.visits += weight
  node.wins += res*weight
  let wins = node.wins + 1.0
  let visits = node.visits + 2.0
  node.score = wins/visits + UCTK*math.sqrt(2*(math.ln(visits)/visits))

proc UCTCmp(x, y: PNode):int =
  return cmp(x.wins,y.wins)

proc UCT*[M,T](rootstate: T, itermax: int, UCTK:float,
               nill_move:M):M =
    var parent : PNode[M]
    parent = nil

    var rootnode = InitNode(state = rootstate, move=nill_move, parent=parent)
    rootnode.untriedMoves = rootstate.GetMoves()

    for i in countup(1,itermax):
        var node = rootnode
        var state = rootstate.Clone()

        # Select
        while (node.untriedMoves.len==0)  and (node.childNodes.len > 0): # node is fully expanded and non-terminal
            assert node != nil
            assert node.childNodes.len > 0
            node = UCTSelectChild(node)
            assert (node.parentNode!=nil)
            assert (node!=nil)
            state.DoMove(node.move)

        # Expand
        if (node.untriedMoves.len > 0): # if we can expand (i.e. state/node is non-terminal)
            let move_id = math.random(node.untriedMoves.len)
            var m = node.untriedMoves[move_id]
            state.DoMove(m)
            node = AddChild(node, m, state) # add child and descend tree
            node.untriedMoves = state.GetMoves()

        # Rollout - this can often be made orders of magnitude quicker using a state.GetRandomMove() function
        var moves = state.GetMoves()
        while moves.len > 0: # while state is non-terminal
            state.DoMove(moves[math.random(moves.len)])
            moves = state.GetMoves()

        # Backpropagate
        while True: # backpropagate from the expanded node and work back to the root node
            Update(node[], state.GetResult(3-node.playerJustMoved), UCTK) # state is terminal. Update node with result from POV of node.playerJustMoved
            if (node.parentNode==nil):
              break
            node = node.parentNode

    algorithm.sort(a=rootnode.ChildNodes, cmp=UCTCmp, order = Descending)
    result = rootnode.ChildNodes[0].move


proc UCTstar*[M,T](rootstate: T, itermax: int, UCTK:float,
               nill_move:M):M =
    var parent : PNode[M]
    parent = nil

    var rootnode = InitNode(state = rootstate, move=nill_move, parent=parent)
    rootnode.untriedMoves = rootstate.GetMoves()

    for i in countup(1,itermax):
        var node = rootnode
        var state = rootstate.Clone()

        # Select
        while (node.untriedMoves.len==0)  and (node.childNodes.len > 0): # node is fully expanded and non-terminal
            assert node != nil
            assert node.childNodes.len > 0
            node = UCTSelectChild(node)
            assert (node.parentNode!=nil)
            assert (node!=nil)
            state.DoMove(node.move)

        # Expand
        if (node.untriedMoves.len > 0): # if we can expand (i.e. state/node is non-terminal)
            let move_id = math.random(node.untriedMoves.len)
            var m = node.untriedMoves[move_id]
            state.DoMove(m)
            node = AddChild(node, m, state) # add child and descend tree
            node.untriedMoves = state.GetMoves()
        # Rollout - this can often be made orders of magnitude quicker using a state.GetRandomMove() function
        var moves = state.GetMoves()
        var weight = 0.0
        var wins = 0.0
        while True: # while state is non-terminal
          moves = state.GetMoves()
          if moves.len == 0:
            weight = 1.0
            wins = state.GetResult(3-node.playerJustMoved)
            break

          # heuristic - is the game now at a predictable state?
          let predicted = state.GetPrediction(3-node.playerJustMoved)
          # how far should we search?
          # maybe related to the state's wins. If rootnode has a high value,
          # then we should probably not guess.
          if predicted.quality > (0.1 * node.visits):
            weight = predicted.quality
            wins = predicted.result
            break

          state.DoMove(moves[math.random(moves.len)])

        assert (0.0<=wins)
        assert (1.0>=wins)
        assert (0.0<=weight)
        assert (1.0>=weight)

        # Backpropagate
        while True: # backpropagate from the expanded node and work back to the root node
            UpdateStar(node[], wins, weight, UCTK) # state is terminal. Update node with result from POV of node.playerJustMoved
            wins = weight-wins
            if (node.parentNode==nil):
              break
            node = node.parentNode

    algorithm.sort(a=rootnode.ChildNodes, cmp=UCTCmp, order = Descending)
    result = rootnode.ChildNodes[0].move

proc UCTPlayGame*[M,T](state: var T, nill_move:M, p1_it:int,UCTK1:float, p2_it:int,UCTK2:float,verbose:bool) =
  var moves = state.GetMoves()
  while moves.len > 0:
      var m: M
      if state.playerJustMoved == 1:
          m = UCT(state, p1_it, UCTK1, nill_move)
      else:
          m = UCT(state, p2_it,UCTK2, nill_move)
      state.DoMove(m)
      if verbose:
        echo(state.to_string)
      moves = state.GetMoves()
      if moves.len == 0:
        break

  if state.GetResult(state.playerJustMoved) == 1.0:
      echo( "Player " & $(state.playerJustMoved) & " wins!")
  elif state.GetResult(3-state.playerJustMoved) == 1.0:
      echo( "Player " & $(3 - state.playerJustMoved) & " wins!")
  else: echo("Nobody wins!")

import times
proc StarVsNostar*[T,M](state:var T,nill_move:M,
                     p1_it:int,UCTK1:float,
                     p2_it:int,UCTK2:float,
                     verbose:bool) =
  var moves = state.GetMoves()
  var t1 = 0.0
  var t2 = 0.0
  while moves.len > 0:
      var m: M
      var t0 = cpuTime()
      if state.playerJustMoved == 1:
          m = UCT(state, p2_it, UCTK2, nill_move)
          t2 += cpuTime() -t0
      else:
          m = UCTstar(state, p1_it, UCTK1, nill_move)
          t1 += cpuTime() -t0
      state.DoMove(m)
      if verbose:
        echo(state.to_string)
      moves = state.GetMoves()
      if moves.len == 0:
        break

  if state.GetResult(state.playerJustMoved) == 1:
      echo( "Player " & $(state.playerJustMoved) & " wins!")
  elif state.GetResult(3-state.playerJustMoved) == 1:
      echo( "Player " & $(3 - state.playerJustMoved) & " wins!")
  else: echo("Nobody wins!")
  echo("P1 time: ",t1," P2 time: ",t2)

proc PlayGames*[T,M](state:var T,nill_move:M,
                     p1_it:int,UCTK1:float,
                     p2_it:int,UCTK2:float,
                     num_games:int,
                     verbose:bool) =
  var s1:T
  for i in count_up(0,num_games-1):
    s1 = state.Clone()
    UCTPlayGame(s1,nill_move,p1_it,UCTK1,p2_it,UCTK2,verbose)
