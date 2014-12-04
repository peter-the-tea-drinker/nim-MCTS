import sequtils
import nimMCTS

type
  Move* = tuple
    x: int
    y: int

  OthelloState* = object of TState
    board: seq[seq[int]]
    size: int
    sz: int
    all_squares: seq[Move]

proc InitState(sz:int):OthelloState{.inline.} =
  assert sz>0
  assert ((sz mod 2) == 0)
  result.playerJustMoved = 2 # At the root pretend the player just moved is p2 - p1 has the first move
  result.board.newSeq(sz)
  result.all_squares.newSeq(sz*sz)
  for y in count_up(0,sz-1):
    result.board[y].newSeq(sz)
    for x in count_up(0,sz-1):
      result.board[y][x]=0
      result.all_squares[x*sz+y]=(x,y)
  let cx = sz div 2
  result.board[cx][cx] = 1
  result.board[cx-1][cx-1] = 1
  result.board[cx-1][cx] = 2
  result.board[cx][cx-1] = 2
  result.sz = sz

method Clone(source:OthelloState):OthelloState{.inline.} =
  ## Create a deep clone of this game state.
  result.playerJustMoved = source.playerJustMoved
  result.board = source.board
  result.sz = source.sz
  result.all_squares = source.all_squares

method IsOnBoard(state: OthelloState,x:int,y:int):bool{.inline.}=
        return ((x >= 0 and x < state.sz) and
                (y >= 0 and y < state.sz))


method AdjacentEnemyDirections(state: OthelloState,x:int,y:int):seq[Move]{.inline.}=
  ## Speeds up GetMoves by only considering squares which are adjacent to an enemy-occupied square.
  result.newSeq(0)
  var i=0
  for move in [[0,+1],[+1,+1],[+1,0],[+1,-1],[0,-1],[-1,-1],[-1,0],[-1,+1]]:
    if (state.IsOnBoard(x+move[0],y+move[1])) and (state.board[x+move[0]][y+move[1]] == state.playerJustMoved):
      i+=1
      result.setLen(i)
      result[i-1]=(move[0],move[1])

method SandwichedCounters(state: OthelloState,x0:int,y0:int,dx:int,dy:int):seq[Move]{.inline.}=
  ## Return the coordinates of all opponent counters sandwiched between (x,y) and my counter.
  var x = x0 + dx
  var y = y0 + dy
  result = @[]
  while state.IsOnBoard(x,y) and state.board[x][y] == state.playerJustMoved:
      result.setLen(result.len+1)
      result[result.len-1] = (x,y)
      x += dx
      y += dy
  if not (state.IsOnBoard(x,y) and state.board[x][y] == 3 - state.playerJustMoved):
      return @[] # nothing sandwiched

method ExistsSandwichedCounter(state: OthelloState,x:int,y:int):bool{.inline.} =
  ## Does there exist at least one counter which would be flipped if my counter was placed at (x,y)?
  for move in state.AdjacentEnemyDirections(x,y):
    if len(state.SandwichedCounters(x,y,move.x,move.y)) > 0:
      return True
  return False

method AdjacentToEnemy(state: OthelloState,x:int,y:int):bool{.inline.} =
  ## Speeds up GetMoves by only considering squares which are adjacent to an enemy-occupied square.
  for move in [(0,+1),(+1,+1),(+1,0),(+1,-1),(0,-1),(-1,-1),(-1,0),(-1,+1)]:
    let dx = move[0]
    let dy = move[1]
    if (state.IsOnBoard(x+dx,y+dy)) and (state.board[x+dx][y+dy] == state.playerJustMoved):
      return True
  return False

method GetAllSandwichedCounters(state: OthelloState,x:int,y:int):seq[Move]{.inline.}=
  ## Is (x,y) a possible move (i.e. opponent counters are sandwiched between (x,y) and my counter in some direction)?
  result.newSeq(0)
  for move in state.AdjacentEnemyDirections(x,y):
    let extend = state.SandwichedCounters(x,y,move.x,move.y)
    let i = result.len
    result.setLen(result.len+extend.len)
    for j in count_up(0,extend.len-1):
      result[i+j]=extend[j]

method DoMove*(state: var OthelloState, move:Move){.inline.} =
  ## Update a state by carrying out the given move.
  ## Must update playerToMove.
  let x = move.x
  let y = move.y
  assert (state.IsOnBoard(x,y) and (state.board[x][y]==0))
  let moves = state.GetAllSandwichedCounters(x,y)
  state.playerJustMoved = 3-state.playerJustMoved
  state.board[x][y]=state.playerJustMoved
  for m in moves:
      state.board[m.x][m.y] = state.playerJustMoved

method GetMoves*(state: OthelloState):seq[Move]{.inline.} =
  ## Get all possible moves from this state.
  result.newSeq(0)
  for t in state.all_squares:
    if ((state.board[t.x][t.y] ==0) and state.ExistsSandwichedCounter(t.x,t.y)):
      result.setLen(result.len+1)
      result[result.len-1]=t

method GetResult*(state: OthelloState, playerjm:int,db:bool):float{.inline.}=
  ## Get the game result from the viewpoint of playerjm.
  var jmcount = 0
  var notjmcount = 0
  for t in state.all_squares:
    if (state.board[t.x][t.y] == playerjm):
      jmcount += 1
    elif (state.board[t.x][t.y] == 3 - playerjm):
      notjmcount += 1
  if db==True:
    echo(jmcount)
    echo(notjmcount)
  if jmcount > notjmcount:
    return 1.0
  elif notjmcount > jmcount:
    return 0.0
  else:
    return 0.5 # draw

method GetResult*(state: OthelloState, playerjm:int):float{.inline.}=
  return GetResult(state, playerjm, False)

method toString*(state: OthelloState): string{.inline.} =
  result = ""
  for i in count_up(0,state.sz-1):
    for j in count_up(0,state.sz-1):
      result = result & ".XO"[state.board[i][j]]
    result = result & "\n"

var state = InitState(8)
let nill_move:Move = (-1,-1)
PlayGames(state,nill_move,400,0.1,400,1.0,1,True)
PlayGames(state,nill_move,40,0.1,40,1.0,10,False)
