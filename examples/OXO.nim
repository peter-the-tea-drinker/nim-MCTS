import sequtils
import nimMCTS
import htmlgen

type
  OXOState* = object of TState
    board: seq[int]
    winner: int

  Move* = int

  Row = tuple
    x: int
    y: int
    z: int

var winning_rows:seq[Row] = @[(0,1,2),(3,4,5),(6,7,8),(0,3,6),(1,4,7),(2,5,8),(0,4,8),(2,4,6)]

proc InitState():OXOState{.inline.} =
  result.playerJustMoved = 2 # At the root pretend the player just moved is p2 - p1 has the first move
  result.board = @[0,0,0,0,0,0,0,0,0] # 0 = empty, 1 = player 1, 2 = player 2
  result.winner=0

method Clone(source:OXOState):OXOState{.inline.} =
  ## Create a deep clone of this game state.
  result.playerJustMoved = source.playerJustMoved
  result.board = source.board
  result.winner = source.winner

method DoMove*(state: var OXOState, move:Move){.inline.} =
  ## Update a state by carrying out the given move.
  ## Must update playerToMove.
  let m = move
  assert m >= 0 and m <= 8 and state.board[m] == 0
  state.playerJustMoved = 3 - state.playerJustMoved
  state.board[m] = state.playerJustMoved
  for row in winning_rows:
    let x = row[0]
    let y = row[1]
    let z = row[2]
    if (state.board[x]>0) and (state.board[x] == state.board[y]) and (state.board[y] == state.board[z]):
        state.winner=state.board[x]

method GetMoves*(state: OXOState):seq[Move]{.inline.} =
  ## Get all possible moves from this state.
  if state.winner>0:
    return @[]
  let squares = to_seq(count_up(0,8))
  result = filter(squares, proc(t:int):bool = return state.board[t] ==0)

method GetResult*(state: OXOState, playerjm:int):float{.inline.} =
  ## Get the game result from the viewpoint of playerjm.
  if state.winner>0:
    if state.winner==playerjm:
      return 1.0
    else:
      return 0.0
  return 0.5

method toString*(state: OXOState): string{.inline.} =
  result = ""
  for i in count_up(0,8):
    result = result & ".XO"[state.board[i]]
    if i mod 3 == 2:
      result = result & "\n"

method toHTML(state: OXOState): string =
  result = "<pre>"
  for i in count_up(0,8):
    if state.board[i]==0:
      result = result & a(id=($i), $i)
    else:
      result = result & ".XO"[state.board[i]]
    if i mod 3 == 2:
      result = result & "<br>"
  result = result & "</pre>"

var state = InitState()
let nill_move = -1
PlayGames(state,nill_move,10,0.5,20000,0.5,2,True)


