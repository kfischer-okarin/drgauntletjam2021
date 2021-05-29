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

  def add_array(other)
    dup.add_array!(other)
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

  def mult_scalar(value)
    dup.mult_scalar!(value)
  end
end

module Entities
  class << self
    def setup(args)
      args.state.new_entities = []
      args.state.entities = {}
      args.state.moving_entities = {}
      self.args = args
    end

    def args=(args)
      @args = args
      @entities = args.state.entities
    end

    def [](id)
      @entities[id]
    end

    def <<(entity)
      @args.state.new_entities << entity.id
      @entities[entity.id] = entity
      @args.state.moving_entities[entity.id] = entity if entity.respond_to? :movement
    end
  end
end

def generate_next_entity_id(args)
  result = args.state.next_entity_id
  args.state.next_entity_id += 1
  result
end

def setup(args)
  args.state.next_entity_id = 1
  args.state.player = args.state.new_entity_strict(
    :player,
    id: generate_next_entity_id(args),
    position: [160, 90],
    movement: [0, 0],
    direction: [0, -1],
    face_direction: [0, -1],
    shooting: false,
    shoot_cooldown: 30,
    time_until_next_shot: 0
  )
  $sprites = {
    player: {
      x: 0, y:0, w: 16, h: 16, path: 'sprites/character.png', source_w: 16, source_h: 16
    }.sprite.tap { |sprite| sprite[:animation] = Animation.new(sprite, :character_down) },
    bullets: []
  }
  Entities.setup args
  Entities << args.state.player
end

def angle_from_direction(direction)
  normalized = [direction.x.sign, direction.y.sign]
  case normalized
  when [0, 1], [0, -1]
    0
  when [1, -1], [-1, 1]
    45
  when [1, 1], [-1, -1]
    -45
  when [1, 0], [-1, 0]
    90
  end
end

def build_bullet_sprite(bullet)
  {
    x: 200, y:100, w: 4, h: 6, path: 'sprites/bullet.png', source_w: 4, source_h: 6,
    r: 81, g: 162, b: 0,
    angle_anchor_x: 0.5, angle_anchor_y: 0.5, angle: angle_from_direction(bullet.movement),
    entity_id: bullet.id
  }.sprite.tap { |sprite|
    sprite[:animation] = Animation.new(sprite, :bullet)
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
  calc_player_movement(args, input_events)
  handle_shoot(args)

  handle_movement(args)
end

def calc_player_movement(args, input_events)
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

  player.shooting = false

  if !shoot_direction.zero?
    player.shooting = true
    player.direction.assign_array! shoot_direction
  elsif !movement.zero?
    player.direction.assign_array! movement
  end

  player.face_direction.assign_array! player.direction if player.direction.x.zero? || player.direction.y.zero?
end

def player_bullet_origin(player)
  case player.face_direction
  when [0, 1]
    player.position.add_array [2, 8]
  when [0, -1]
    player.position.add_array [-2, 0]
  when [1, 0]
    player.position.add_array [6, 6]
  when [-1, 0]
    player.position.add_array [-6, 6]
  end
end

def handle_shoot(args)
  player = args.state.player
  player.time_until_next_shot -= 1 if player.time_until_next_shot.positive?
  return if !player.shooting || player.time_until_next_shot.positive?

  direction = player.direction
  bullet = args.state.new_entity_strict(
    :bullet,
    id: generate_next_entity_id(args),
    position: player_bullet_origin(player),
    movement: direction.mult_scalar(2)
  )

  Entities << bullet
  player.time_until_next_shot = player.shoot_cooldown
end

def handle_movement(args)
  args.state.moving_entities.each_value do |entity|
    entity.position.add_array! entity.movement
  end
end

def next_player_animation(player)
  moving = !player.movement.zero?

  case player.face_direction
  when [0, 1]
    if moving
      player.shooting ? :character_shoot_walk_up : :character_walk_up
    else
      player.shooting ? :character_shoot_up : :character_up
    end
  when [1, 0]
    if moving
      player.shooting ? :character_shoot_walk_right : :character_walk_right
    else
      player.shooting ? :character_shoot_right : :character_right
    end
  when [-1, 0]
    if moving
      player.shooting ? :character_shoot_walk_left : :character_walk_left
    else
      player.shooting ? :character_shoot_left : :character_left
    end
  when [0, -1]
    if moving
      player.shooting ? :character_shoot_walk_down : :character_walk_down
    else
      player.shooting ? :character_shoot_down : :character_down
    end
  end
end

def render(args)
  screen = args.outputs[:screen]
  add_new_entity_sprites(args)
  render_bullets(args, screen)
  render_player(args, screen)

  args.outputs.primitives << {
    x: 0, y: 0, w: 1280, h: 720,
    path: :screen, source_x: 0, source_y: 0, source_w: 320, source_h: 180
  }
end

def add_new_entity_sprites(args)
  args.state.new_entities.each do |entity_id|
    entity = Entities[entity_id]
    case entity.entity_type
    when :bullet
      $sprites[:bullets] << build_bullet_sprite(entity)
    end
  end
  args.state.new_entities.clear
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
  outputs.primitives << [player.position, 1, 1].solid
end

def render_bullets(args, outputs)
  $sprites[:bullets].each do |sprite|
    sprite[:animation].tick
    bullet = Entities[sprite[:entity_id]]
    sprite.x = bullet.position.x - 2
    sprite.y = bullet.position.y - 3
  end
  outputs.primitives << $sprites[:bullets]
end

def tick(args)
  setup(args) if args.tick_count.zero?

  Entities.args = args
  world_tick(args, process_input(args))
  render(args)

  args.outputs.debug << [0, 720, $gtk.current_framerate.to_i.to_s].label
end

$gtk.reset
