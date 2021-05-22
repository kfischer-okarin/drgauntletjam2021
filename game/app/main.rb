def setup(args)
  args.state.player = args.state.new_entity_strict(:player, position: [0, 0])
end

def process_input(args)
  keyboard = args.inputs.keyboard

  {
    movement: [keyboard.left_right, keyboard.up_down]
  }
end

def world_tick(args, input_events)
  player = args.state.player
  player.position.x += input_events[:movement].x
  player.position.y += input_events[:movement].y
end

def render(args)
  player = args.state.player
  args.outputs[:screen].primitives << {
    x: player.position.x, y: player.position.y, w: 16, h: 16,
    path: 'sprites/character.png', source_w: 16, source_h: 16, source_x: 16, source_y: 5 * 16
  }
  args.outputs.primitives << {
    x: 0, y: 0, w: 1280, h: 720,
    path: :screen, source_x: 0, source_y: 0, source_w: 320, source_h: 180
  }
end

def tick(args)
  setup(args) if args.tick_count.zero?
  world_tick(args, process_input(args))
  render(args)
end

$gtk.reset
