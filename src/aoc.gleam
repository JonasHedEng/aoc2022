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

fn max_height(
  in grid: Grid,
  for coord: Coord,
  direction direction: Direction,
  current_max current_height: Result(Int, Nil),
) -> Result(Int, Nil) {
  let next_coord_res = coord_towards(direction, from: coord, in: grid)
  let next_height_res =
    next_coord_res
    |> result.then(apply: fn(c) { height_at(c, in: grid) })

  case next_coord_res, next_height_res, current_height {
    Ok(next_coord), Ok(next_height), Ok(height) ->
      max_height(grid, next_coord, direction, Ok(int.max(next_height, height)))
    Ok(next_coord), Ok(next_height), Error(Nil) ->
      max_height(grid, next_coord, direction, Ok(next_height))
    Error(_), Error(_), current_height -> current_height
  }
}

fn is_visible_from(in grid: Grid, for coord: Coord) -> List(Direction) {
  assert Ok(height) = height_at(coord, in: grid)

  let visible_from =
    [Up, Down, Left, Right]
    |> list.map(fn(dir) {
      let max_h =
        max_height(
          in: grid,
          for: coord,
          direction: dir,
          current_max: Error(Nil),
        )
      case max_h {
        Ok(h) if h >= height -> []
        _ -> [dir]
      }
    })
    |> list.flatten

  visible_from
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

fn sum_is_visible(row_id y: Int, x_range: List(Int), in grid: Grid) -> Int {
  x_range
  |> list.map(fn(x) { is_visible_from(in: grid, for: #(x, y)) })
  |> list.filter(fn(dirs) { !list.is_empty(dirs) })
  |> list.length
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
  |> list.map(fn(row_id) { sum_is_visible(row_id, col_ids, grid) })
  |> int.sum
  |> io.debug
}
