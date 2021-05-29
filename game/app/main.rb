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

  def mult_scalar!(value)
    index = 0
    while index < length
      self[index] *= value
      index += 1
    end
    self
  end
end

def generate_next_entity_id(args)
  result = args.state.next_entity_id
  args.state.next_entity_id += 1
  result
end

def add_entity(args, entity)
  args.state.entities[entity.id] = entity
  args.state.moving_entities[entity.id] = entity if entity.respond_to? :movement
end

def setup(args)
  args.state.next_entity_id = 1
  args.state.player = args.state.new_entity_strict(
    :player,
    id: generate_next_entity_id(args),
    position: [160, 90],
    movement: [0, 0],
    direction: [0, -1]
  )
  $sprites = {
    player: {
      x: 0, y:0, w: 16, h: 16, path: 'sprites/character.png', source_w: 16, source_h: 16
    }.sprite.tap { |sprite| sprite[:animation] = Animation.new(sprite, :character_down) },
    bullets: [
      {
        x: 200, y:100, w: 4, h: 6, path: 'sprites/bullet.png', source_w: 4, source_h: 6,
        angle_anchor_x: 0.5, angle_anchor_y: 0.5,
      }.sprite.tap { |sprite| sprite[:animation] = Animation.new(sprite, :bullet) }
    ]
  }
  args.state.entities = {}
  args.state.moving_entities = {}
  add_entity(args, args.state.player)
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

    player.movement.mult_scalar!(walk_shoot_same ? 1.2 : 0.7)
  end

  if !shoot_direction.zero?
    player.direction.assign_array! shoot_direction
  elsif !movement.zero?
    player.direction.assign_array! movement
  end

  handle_movement(args)
end

def handle_movement(args)
  args.state.moving_entities.each_value do |entity|
    entity.position.add_array! entity.movement
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

  next_animation_id = next_player_animation(player)
  if next_animation_id && next_animation_id != animation.id
    player_sprite[:animation] = Animation.new(player_sprite, next_animation_id)
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
