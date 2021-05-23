class Array
  def zero?
    all?(&:zero?)
  end

  def add_array!(other)
    index = 0
    while index < length
      self[index] += other[index]
      index += 1
    end
    self
  end

  def assign_array!(other)
    index = 0
    while index < length
      self[index] = other[index]
      index += 1
    end
    self
  end
end

def setup(args)
  args.state.player = args.state.new_entity_strict(
    :player,
    position: [0, 0],
    direction: [0, -1]
  )
  $sprites = {
    player: {
      x: 0, y:0, w: 16, h: 16, path: 'sprites/character.png', source_w: 16, source_h: 16
    }.sprite
  }
end

def process_input(args)
  keyboard = args.inputs.keyboard

  {
    movement: [keyboard.left_right, keyboard.up_down]
  }
end

def world_tick(args, input_events)
  player = args.state.player
  movement = input_events[:movement]
  unless movement.zero?
    player.position.add_array! movement
    player.direction.assign_array! movement
  end
end

def render(args)
  player = args.state.player
  player_sprite = $sprites[:player]
  player_sprite.x = player.position.x
  player_sprite.y = player.position.y
  player_sprite.source_x = 16 # TODO: Animation
  if player.direction == [0, -1]
    player_sprite.source_y = 5 * 16
    player_sprite.flip_horizontally = false
  elsif player.direction == [1, 0]
    player_sprite.source_y = 4 * 16
    player_sprite.flip_horizontally = false
  elsif player.direction == [-1, 0]
    player_sprite.source_y = 4 * 16
    player_sprite.flip_horizontally = true
  elsif player.direction == [0, 1]
    player_sprite.source_y = 3 * 16
    player_sprite.flip_horizontally = false
  end

  args.outputs[:screen].primitives << player_sprite
  args.outputs.primitives << {
    x: 0, y: 0, w: 1280, h: 720,
    path: :screen, source_x: 0, source_y: 0, source_w: 320, source_h: 180
  }
end

def tick(args)
  setup(args) if args.tick_count.zero?
  world_tick(args, process_input(args))
  render(args)

  args.outputs.debug << [0, 720, $gtk.current_framerate.to_i.to_s].label
end

$gtk.reset
