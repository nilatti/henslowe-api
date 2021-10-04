namespace :export do
  desc "Export users"
  task :export_to_seeds => :environment do
    all_models = %w(
      theater
      author
      play
      character_group
      character
      act
      scene
      french_scene
      line
      word
      sound_cue
      stage_direction
      on_stage
      entrance_exit
      specialization
    )
    Theater.all.each do |theaters|
      excluded_keys = ['created_at', 'updated_at', 'id']
      serialized = theaters
        .serializable_hash
        .delete_if{|key,value| excluded_keys.include?(key)}
      puts "Theater.create(#{serialized})"
    end
    Author.all.each do |authors|
      excluded_keys = ['created_at', 'updated_at', 'id']
      serialized = authors
        .serializable_hash
        .delete_if{|key,value| excluded_keys.include?(key)}
      puts "Author.create(#{serialized})"
    end
  end
end
