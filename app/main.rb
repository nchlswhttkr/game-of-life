def tick args
  width = 120
  height = 60
  # make cells as big as possible but still fit within boundss
  size = [(1280 - 40) / width, (720 - 70) / height].min.floor
  x_offset = (20 + (1280 - 40 - width * size) / 2).floor
  y_offset = (50 + (720 - 70 - height * size) / 2).floor

  args.state.cells ||= Array.new(width) { Array.new(height, false) }
  args.state.running ||= false
  args.state.rate ||= 10

  args.state.mouse_held ||= false
  args.state.last_cell ||= [-1, -1]
  mouse = args.inputs.mouse
  if mouse.down
    args.state.mouse_held = true
  end
  if mouse.up
    args.state.mouse_held = false
  end
  if args.state.mouse_held
    if x_offset <= mouse.x && mouse.x < x_offset + width * size && y_offset <= mouse.y && mouse.y < y_offset + height * size
      x = ((mouse.x - x_offset) / size).floor
      y = ((mouse.y - y_offset) / size).floor

      # dragged to new cell or clicked last cell
      if [x, y] != args.state.last_cell || mouse.click
        args.state.cells[x][y] = !args.state.cells[x][y]
        args.state.last_cell = [x, y]
      end
    end
  end

  if args.inputs.keyboard.key_down.backspace
    args.state.running = false
    args.state.cells = Array.new(width) { Array.new(height, false) }
  end

  if args.state.running and args.state.tick_count % args.state.rate == 0
    neighbours = Array.new(width) { Array.new(height, 0) }
    args.state.cells.each_with_index { |row, x|
      row.each_with_index { |alive, y|
        if alive
          neighbours[x - 1][y - 1] += 1
          neighbours[x][y - 1] += 1
          neighbours[(x + 1) % width][y - 1] += 1
          neighbours[x - 1][y] += 1
          neighbours[(x + 1) % width][y] += 1
          neighbours[x - 1][(y + 1) % height] += 1
          neighbours[x][(y + 1) % height] += 1
          neighbours[(x + 1) % width][(y + 1) % height] += 1
        end
      }
    }

    args.state.cells.each_with_index { |row, x|
      row.map!.with_index { |alive, y|
        neighbours[x][y] == 3 || (alive && neighbours[x][y] == 2)
      }
    }
  end

  # toggle start/stop
  if args.inputs.keyboard.key_down.space
    args.state.running = !args.state.running
  end

  # change step speed
  if args.inputs.keyboard.key_down.down
    args.state.rate += 1
  end
  if args.inputs.keyboard.key_down.up
    args.state.rate = [args.state.rate - 1, 1].max
  end

  # draw most of the page (background, text, grid)
  args.outputs.solids << [0, 0, 1280, 720, 255, 255, 255, 255]
  args.outputs.borders << [x_offset, y_offset, size * width, size * height, 127, args.state.running ? 0 : 127, 127, 255]
  (1..(width - 1)).each { |i|
    args.outputs.lines << [x_offset + i * size, y_offset, x_offset + i * size, y_offset + height * size, 127, 127, 127, 127]
  }
  (1..(height - 1)).each { |i|
    args.outputs.lines << [x_offset, y_offset + i * size, x_offset + width * size, y_offset + i * size, 127, 127, 127, 127]
  }
  args.outputs.labels << [x_offset, 40, '%d ticks/second, stepping every %d ticks' % [args.gtk.current_framerate.ceil, args.state.rate]]

  # draw the cells themselves, stop if none are alive
  some_surviving = false
  args.state.cells.each.with_index { |row, x|
    row.each.with_index { |alive, y|
      if alive
        args.outputs.solids << [x_offset + x * size, y_offset + y * size, size, size, 0, 0, 0, 255]
        some_surviving = true
      end
    }
  }
  if !some_surviving
    args.state.running = false
  end
end
