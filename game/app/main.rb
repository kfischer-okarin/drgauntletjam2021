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

$fl = 10

$animations = {
  character_down: [
    { values: { source_x: 16, source_y: 5 * 16, flip_horizontally: false } }
  ],
  character_left: [
    { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: true } }
  ],
  character_right: [
    { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: false } }
  ],
  character_up: [
    { values: { source_x: 16, source_y: 3 * 16, flip_horizontally: false } }
  ],
  character_walk_down: [
    { values: { source_x: 32, source_y: 5 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 16, source_y: 5 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 0, source_y: 5 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 16, source_y: 5 * 16, flip_horizontally: false }, length: $fl }
  ],
  character_walk_left: [
    { values: { source_x: 32, source_y: 4 * 16, flip_horizontally: true }, length: $fl },
    { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: true }, length: $fl },
    { values: { source_x: 0, source_y: 4 * 16, flip_horizontally: true }, length: $fl },
    { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: true }, length: $fl }
  ],
  character_walk_right: [
    { values: { source_x: 32, source_y: 4 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 0, source_y: 4 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: false }, length: $fl }
  ],
  character_walk_up: [
    { values: { source_x: 32, source_y: 3 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 16, source_y: 3 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 0, source_y: 3 * 16, flip_horizontally: false }, length: $fl },
    { values: { source_x: 16, source_y: 3 * 16, flip_horizontally: false }, length: $fl }
  ]
}

class Animation
  attr_reader :id

  def initialize(id)
    @id = id
    @frames = $animations[id]
    @current_frame = @frames[0]
    @frame_index = 0
    @frame_tick = 0
    @updated = true
  end

  def updated?
    @updated
  end

  def frame_values
    @current_frame[:values]
  end

  def tick
    @updated = false if @updated

    frame_length = @current_frame[:length]
    return unless frame_length

    @frame_tick += 1
    if @frame_tick >= frame_length
      @frame_tick = 0
      @frame_index = (@frame_index + 1) % @frames.length
      @current_frame = @frames[@frame_index]
      @updated = true
    end
  end
end


def setup(args)
  args.state.player = args.state.new_entity_strict(
    :player,
    position: [160, 90],
    movement: [0, 0],
    direction: [0, -1]
  )
  $sprites = {
    player: {
      x: 0, y:0, w: 16, h: 16, path: 'sprites/character.png', source_w: 16, source_h: 16,
      animation: Animation.new(:character_down)
    }.sprite
  }
end

def calc_axis_value(positive, negative)
  if positive
    negative ? 0 : 1
  elsif negative
    positive ? 0 : -1
  else
    0
  end
end

def process_input(args)
  keyboard = args.inputs.keyboard
  key_held = keyboard.key_held

  {
    movement: [
      calc_axis_value(key_held.d, key_held.a),
      calc_axis_value(key_held.w, key_held.s)
    ]
  }
end

def world_tick(args, input_events)
  player = args.state.player
  movement = input_events[:movement]
  player.movement.assign_array! movement
  unless movement.zero?
    player.position.add_array! movement
    player.direction.assign_array! movement
  end
end

def next_player_animation(player)
  moving = !player.movement.zero?

  case player.direction
  when [0, 1]
    moving ? :character_walk_up : :character_up
  when [1, 0]
    moving ? :character_walk_right : :character_right
  when [-1, 0]
    moving ? :character_walk_left : :character_left
  when [0, -1]
    moving ? :character_walk_down : :character_down
  end
end

def render(args)
  player = args.state.player
  player_sprite = $sprites[:player]
  player_sprite.x = player.position.x - 8
  player_sprite.y = player.position.y
  animation = player_sprite[:animation]

  if animation.updated?
    animation.frame_values.each do |attribute, value|
      player_sprite[attribute] = value
    end
  end

  next_animation_id = next_player_animation(player)
  if next_animation_id && next_animation_id != animation.id
    player_sprite[:animation] = Animation.new(next_animation_id)
  else
    animation.tick
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
