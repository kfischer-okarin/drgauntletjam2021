require 'app/animations.rb'

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
    ],
    shoot_direction: [
      calc_axis_value(key_held.right, key_held.left),
      calc_axis_value(key_held.up, key_held.down)
    ]
  }
end

def world_tick(args, input_events)
  player = args.state.player
  movement = input_events[:movement]
  shoot_direction = input_events[:shoot_direction]
  player.movement.assign_array! movement

  unless movement.zero?
    walk_shoot_same = shoot_direction.zero? ||
      (!shoot_direction.x.zero? && shoot_direction.x == movement.x) ||
      (!shoot_direction.y.zero? && shoot_direction.y == movement.y)
    if walk_shoot_same
      player.position.x += movement.x * 1.2
      player.position.y += movement.y * 1.2
    else
      player.position.x += movement.x * 0.7
      player.position.y += movement.y * 0.7
    end
  end

  if !shoot_direction.zero?
    player.direction.assign_array! shoot_direction
  elsif !movement.zero?
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
  screen = args.outputs[:screen]
  render_player(args, screen)

  args.outputs.primitives << {
    x: 0, y: 0, w: 1280, h: 720,
    path: :screen, source_x: 0, source_y: 0, source_w: 320, source_h: 180
  }
end

def render_player(args, outputs)
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

  outputs.primitives << player_sprite
end

def tick(args)
  setup(args) if args.tick_count.zero?
  world_tick(args, process_input(args))
  render(args)

  args.outputs.debug << [0, 720, $gtk.current_framerate.to_i.to_s].label
end

$gtk.reset
