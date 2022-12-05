import gleam/list
import gleam/int
import gleam/io
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/pair
import gleam/result
import gleam/string
import gleam/erlang/file

fn load_input_lines() -> List(String) {
  assert Ok(content) = file.read("input.txt")

  string.split(content, on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
}

// PARSING

type Instruction {
  Instruction(amount: Int, from: Int, to: Int)
}

type Procedure {
  Procedure(lanes: Map(Int, List(String)), instructions: List(Instruction))
}

fn get_next_crate(str: String) -> Result(#(Option(String), String), String) {
  let lane_chars =
    str
    |> string.slice(0, 3)
    |> string.to_graphemes
  let rest =
    str
    |> string.slice(4, string.length(str))

  case lane_chars {
    ["[", crate, "]"] -> Ok(#(Some(crate), rest))
    [" ", " ", " "] -> Ok(#(None, rest))
    _ -> Error("Not crate or empty")
  }
}

fn parse_crate_row(str: String, lane_index: Int) -> List(#(Int, String)) {
  assert Ok(#(next_crate, rest)) = get_next_crate(str)
  let indexed_crate =
    next_crate
    |> option.map(fn(c) { #(lane_index, c) })

  case indexed_crate, rest {
    None, "" -> []
    None, rest -> parse_crate_row(rest, lane_index + 1)
    Some(crate), "" -> [crate]
    Some(crate), rest -> [crate, ..parse_crate_row(rest, lane_index + 1)]
  }
}

fn construct_stack_map(
  stack_map: Map(Int, List(String)),
  crate_row: List(#(Int, String)),
) -> Map(Int, List(String)) {
  case crate_row {
    [] -> stack_map

    [#(lane, crate), ..rest] ->
      case map.get(stack_map, lane) {
        Error(_) ->
          stack_map
          |> map.insert(lane, [crate])
          |> construct_stack_map(rest)
        Ok(stack) ->
          stack_map
          |> map.insert(lane, [crate, ..stack])
          |> construct_stack_map(rest)
      }
  }
}

fn parse_instruction(line: String) -> Instruction {
  let parts = string.split(line, on: " ")

  assert Ok([amount, from, to]) = case parts {
    ["move", amount, "from", from, "to", to] ->
      [amount, from, to]
      |> list.map(int.parse)
      |> result.all
    _ -> Error(Nil)
  }

  Instruction(amount: amount, from: from, to: to)
}

fn parse_starting_stacks(lines: List(String)) -> Procedure {
  let stack_lines =
    lines
    |> list.take_while(fn(line) { string.contains(line, "[") })

  let stacks =
    stack_lines
    |> list.map(fn(line) { parse_crate_row(line, 1) })
    |> list.reverse
    |> list.fold(from: map.new(), with: construct_stack_map)

  let instruction_lines =
    lines
    |> list.split(list.length(stack_lines) + 1)
    |> pair.second

  let instructions =
    instruction_lines
    |> list.map(parse_instruction)

  Procedure(lanes: stacks, instructions: instructions)
}

fn execute(
  on lanes: Map(Int, List(String)),
  do instruction: Instruction,
) -> Map(Int, List(String)) {
  let Instruction(amount, from, to) = instruction

  assert Ok(from_stack) = map.get(lanes, from)
  let #(crates, rest_from) = list.split(from_stack, at: amount)

  assert Ok(to_stack) = map.get(lanes, to)

  let new_to = list.flatten([crates, to_stack])
  lanes
  |> map.insert(for: from, insert: rest_from)
  |> map.insert(for: to, insert: new_to)
}

fn run_procedure(proc: Procedure) -> Map(Int, List(String)) {
  case proc.instructions {
    [] -> proc.lanes
    [instruction, ..rest] -> {
      let lanes =
        proc.lanes
        |> execute(do: instruction)
      Procedure(lanes: lanes, instructions: rest)
      |> run_procedure
    }
  }
}

pub fn main() {
  let lines = load_input_lines()

  let procedure = parse_starting_stacks(lines)
  let result =
    procedure
    |> run_procedure

  assert Ok(top_crates) =
    result
    |> map.to_list
    |> list.map(pair.second)
    |> list.map(list.reverse)
    |> list.map(list.last)
    |> result.all
  string.concat(top_crates)
  |> io.println
}
