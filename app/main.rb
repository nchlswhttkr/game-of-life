def tick args
  width = 120
  height = 60
  size = [(1280 - 40) / width, (720 - 70) / height].min.floor
  x_offset = 20 + (1280 - 40 - width * size) / 2
  y_offset = 50 + (720 - 70 - height * size) / 2

  args.state.cells ||= [false] * width * height
  args.state.running ||= false
  args.state.rate ||= 10

  mouse = args.inputs.mouse
  if mouse.click
    if x_offset <= mouse.x && mouse.x < x_offset + width * size && y_offset <= mouse.y && mouse.y < y_offset + height * size
      i = ((mouse.x - x_offset) / size).floor + width * ((mouse.y - y_offset) / size).floor
      args.state.cells[i] = !args.state.cells[i]
    end
  end

  if args.inputs.keyboard.key_down.backspace
    args.state.running = false
    args.state.cells = [false] * width * height
  end

  if args.state.running and args.state.tick_count % args.state.rate == 0
    neighbours = [0] * width * height
    args.state.cells.each_index { |i|
      if args.state.cells[i] # alive cells notify neighbours
        left = i % width > 0
        right = i % width < width - 1
        above = i / width < height - 1
        below = i >= width

        if below && left
          neighbours[i - width - 1] += 1
        end
        if below
          neighbours[i - width] += 1
        end
        if below && right
          neighbours[i - width + 1] += 1
        end
        if left
          neighbours[i - 1] += 1
        end
        if right
          neighbours[i + 1] += 1
        end
        if above && left
          neighbours[i + width - 1] += 1
        end
        if above
          neighbours[i + width] += 1
        end
        if above && right
          neighbours[i + width + 1] += 1
        end
      end
    }

    args.state.cells.map!.with_index { |alive, i| neighbours[i] == 3 || (alive && neighbours[i] == 2) }
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
    args.state.rate -= args.state.rate > 1 ? 1 : 0
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
  args.state.cells.each.with_index { |alive, i|
    if alive
      args.outputs.solids << [x_offset + (i % width) * size, y_offset + (i / width).floor * size, size, size, 0, 0, 0, 255]
      some_surviving = true
    end
  }
  if !some_surviving
    args.state.running = false
  end
end
