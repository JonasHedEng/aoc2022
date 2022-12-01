import gleam/erlang/file
import gleam/list
import gleam/int
import gleam/io
import gleam/option.{Option, Some, None}
import gleam/string

fn load_input_lines() -> List(String) {
  assert Ok(content) = file.read("input.txt")

  string.split(content, on: "\n")
}

fn parse_line(line: String) -> Int {
  assert Ok(n) = int.parse(line)
  n
}

fn process_line(line: String) -> Option(Int) {
  case line {
    "" -> None
    n -> Some(parse_line(n))
  }
}

fn sum_lines(lines: List(Option(Int))) -> List(Int) {
  case lines {
    [] -> []
    [None, ..tail] -> [0, ..sum_lines(tail)]
    [Some(head), ..tail] -> {
      case sum_lines(tail) {
        [] -> [head]
        [inner_head, ..inner] -> [head+inner_head, ..inner]
      }
    }
  }
}

fn top_cals(lines: List(String), take n: Int) -> List(Int) {
  let processed_lines = list.map(lines, with: process_line)

  let summed = sum_lines(processed_lines)

  list.sort(summed, by: int.compare)
    |> list.reverse
    |> list.take(n)
}

pub fn main() {
  let content = load_input_lines()
  let cals = top_cals(content, take: 3)

  io.println(int.to_string(int.sum(cals)))
}
