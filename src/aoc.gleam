import gleam/erlang/file
import gleam/list
import gleam/int
import gleam/io
import gleam/order.{Eq, Gt, Lt, Order}
import gleam/string

fn load_input_lines() -> List(String) {
  assert Ok(content) = file.read("input.txt")

  string.split(content, on: "\n")
}

type Action {
  Rock
  Paper
  Scissor
}

type Result {
  Loss
  Draw
  Win
}

fn parse_action(from str: String) -> Action {
  case str {
    "A" -> Rock
    "B" -> Paper
    "C" -> Scissor
  }
}

fn parse_wanted_result(from str: String) -> Result {
  case str {
    "X" -> Loss
    "Y" -> Draw
    "Z" -> Win
  }
}

fn action_for(result: Result, against action: Action) -> Action {
  case action, result {
    Rock, Draw -> Rock
    Rock, Win -> Paper
    Rock, Loss -> Scissor

    Paper, Loss -> Rock
    Paper, Draw -> Paper
    Paper, Win -> Scissor

    Scissor, Win -> Rock
    Scissor, Loss -> Paper
    Scissor, Draw -> Scissor
  }
}

fn round_to_score(wanted_result: Result) -> Int {
  case wanted_result {
    Loss -> 0
    Draw -> 3
    Win -> 6
  }
}

fn action_to_score(act: Action) -> Int {
  case act {
    Rock -> 1
    Paper -> 2
    Scissor -> 3
  }
}

fn result(action: Action, wanted_result: Result) -> List(Int) {
  let my_action = action_for(wanted_result, against: action)
  let round_score = round_to_score(wanted_result)
  let action_score = action_to_score(my_action)

  [action_score, round_score]
}

fn rock_paper_scissors(lines: List(String)) -> List(List(Int)) {
  let raw_rounds =
    lines
    |> list.filter(fn(line) { line != "" })
    |> list.map(fn(line) { string.split(line, " ") })

  let rounds =
    raw_rounds
    |> list.map(fn(raw_round) {
      let [raw_action, raw_result] = raw_round

      let opponent_action = parse_action(raw_action)
      let wanted_result = parse_wanted_result(raw_result)

      #(opponent_action, wanted_result)
    })

  let scores =
    rounds
    |> list.map(fn(plan) {
      let #(action, wanted_result) = plan
      result(action, wanted_result)
    })

  scores
}

pub fn main() {
  let lines = load_input_lines()
  let scores = rock_paper_scissors(lines)

  let total_score =
    scores
    |> list.flatten
    |> int.sum
  io.println(int.to_string(total_score))
}
