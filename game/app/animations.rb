class Animation
  attr_reader :id

  def initialize(sprite, animation_id)
    @sprite = sprite
    @id = animation_id
    @frames = ANIMATIONS[animation_id]
    @current_frame = @frames[0]
    @frame_index = 0
    @frame_tick = 0
    @updated = true
  end

  def apply_to_sprite
    @current_frame[:values].each do |attribute, value|
      @sprite[attribute] = value
    end
  end

  def tick
    apply_to_sprite if @updated

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

  ANIMATIONS = {
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
      { values: { source_x: 32, source_y: 5 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 16, source_y: 5 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 0, source_y: 5 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 16, source_y: 5 * 16, flip_horizontally: false }, length: 10 }
    ],
    character_walk_left: [
      { values: { source_x: 32, source_y: 4 * 16, flip_horizontally: true }, length: 10 },
      { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: true }, length: 10 },
      { values: { source_x: 0, source_y: 4 * 16, flip_horizontally: true }, length: 10 },
      { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: true }, length: 10 }
    ],
    character_walk_right: [
      { values: { source_x: 32, source_y: 4 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 0, source_y: 4 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 16, source_y: 4 * 16, flip_horizontally: false }, length: 10 }
    ],
    character_walk_up: [
      { values: { source_x: 32, source_y: 3 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 16, source_y: 3 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 0, source_y: 3 * 16, flip_horizontally: false }, length: 10 },
      { values: { source_x: 16, source_y: 3 * 16, flip_horizontally: false }, length: 10 }
    ]
  }
end
