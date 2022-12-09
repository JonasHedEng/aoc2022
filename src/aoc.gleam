import gleam/list
import gleam/int
import gleam/io
import gleam/result
import gleam/string
import gleam/erlang/file

fn load_input_lines() -> List(String) {
  assert Ok(content) = file.read("input.txt")

  string.split(content, on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
}

type Grid {
  Grid(rows: List(List(Int)))
}

type Coord =
  #(Int, Int)

fn height_at(coord: Coord, in grid: Grid) -> Result(Int, Nil) {
  case coord {
    #(x, y) if x < 0 || y < 0 -> Error(Nil)
    #(x, y) -> {
      try row =
        grid.rows
        |> list.at(y)
      row
      |> list.at(x)
    }
  }
}

fn coord_towards(
  direction direction: Direction,
  from coord: Coord,
  in grid: Grid,
) -> Result(Coord, Nil) {
  let new_coord = case direction, coord {
    Up, #(x, y) -> #(x, y - 1)
    Down, #(x, y) -> #(x, y + 1)
    Left, #(x, y) -> #(x - 1, y)
    Right, #(x, y) -> #(x + 1, y)
  }

  new_coord
  |> height_at(in: grid)
  |> result.replace(new_coord)
}

type Direction {
  Up
  Down
  Left
  Right
}

fn viewing_distance(
  in grid: Grid,
  for coord: Coord,
  direction direction: Direction,
  from height: Int,
) -> Int {
  let next_coord_res = coord_towards(direction, from: coord, in: grid)
  let next_height_res =
    next_coord_res
    |> result.then(apply: fn(c) { height_at(c, in: grid) })

  case next_coord_res, next_height_res {
    Ok(_), Ok(next_height) if next_height >= height -> 1
    Ok(next_coord), Ok(next_height) ->
      1 + viewing_distance(grid, next_coord, direction, height)
    Error(_), Error(_) -> 0
  }
}

fn scenic_score(in grid: Grid, for coord: Coord) -> Int {
  assert Ok(height) = height_at(coord, in: grid)

  let score =
    [Up, Down, Left, Right]
    |> list.map(fn(dir) {
      viewing_distance(in: grid, for: coord, direction: dir, from: height)
    })
    |> int.product

  score
}

fn parse_grid(lines: List(String)) -> Grid {
  let rows: List(List(Int)) =
    lines
    |> list.map(fn(line) {
      let nums = string.to_graphemes(line)
      assert Ok(parsed) =
        nums
        |> list.map(int.parse)
        |> result.all
      parsed
    })

  Grid(rows: rows)
}

fn most_scenic(row_id y: Int, x_range: List(Int), in grid: Grid) -> Int {
  x_range
  |> list.map(fn(x) { scenic_score(in: grid, for: #(x, y)) })
  |> list.fold(0, int.max)
}

pub fn main() {
  let lines = load_input_lines()
  let grid = parse_grid(lines)

  assert Ok(width) =
    grid.rows
    |> list.first
    |> result.map(list.length)

  let height =
    grid.rows
    |> list.length

  let row_ids = list.range(0, height - 1)
  let col_ids = list.range(0, width - 1)

  row_ids
  |> list.map(fn(row_id) { most_scenic(row_id, col_ids, grid) })
  |> list.fold(0, int.max)
  |> io.debug
}
