module LineCountable
  extend ActiveSupport::Concern

  # Syllable-weighted line count, Shakespearean verse convention (a ten-syllable
  # line counts as 1.0; "I will, my lord" counts as ~0.4). original_line_count
  # reflects the original text; new_line_count uses each line's new_content
  # where present (a line cut to blank new_content contributes 0), falling
  # back to original_content otherwise. Always computed live from lines, never
  # a stored/cached value, so it can't go stale.
  SYLLABLES_PER_LINE = 10.0

  def original_line_count
    line_counts[:original]
  end

  def new_line_count
    line_counts[:new]
  end

  # Ensures these always appear in this model's JSON regardless of the
  # caller's as_json options, so every consumer sees the same live numbers.
  def as_json(options = {})
    super(options.merge(
      methods: (Array(options[:methods]) + [:original_line_count, :new_line_count]).uniq
    ))
  end

  private

  def line_counts
    @line_counts ||= lines.reduce({ original: 0.0, new: 0.0 }) do |sums, line|
      original_value = syllable_value(line.original_content)
      new_value = line.new_content.nil? ? original_value : syllable_value(line.new_content)
      { original: sums[:original] + original_value, new: sums[:new] + new_value }
    end
  end

  def syllable_value(content)
    return 0.0 if content.blank?
    content.count_syllables / SYLLABLES_PER_LINE
  end
end
