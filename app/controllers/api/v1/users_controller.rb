module Api
  module V1
class UsersController < ApiController
  # load_and_authorize_resource
  skip_before_action :authenticate_request, only: [:create]
  before_action :set_user, only: %i[show update destroy upload_headshot]

  # GET /Users
  def index
    @users = current_user.visible_users
    json_response(@users.as_json(only: %i[
      id
      email
      first_name
      last_name
      middle_name
      preferred_name
      program_name
      fake
      role
      bio
      city
      state
      website
      gender
      timezone
      subscription_status
      subscription_end_date
      created_at
      updated_at
    ]))
  end

  # GET /Users/1
  def show
    if current_user && @user
      overlap = current_user.jobs_overlap(@user)
      if ["theater admin", "production admin", "self", "superadmin"].include?(overlap)
        json_response(@user.as_json(include:
          [
            :conflicts,
            :conflict_patterns,
            jobs: {
              include: [
                character: {
                  only: :name
                },
                character_group: {
                  only: :name
                },
                production: {
                  include: {
                    play: {
                      only: [
                        :id,
                        :title
                        ]
                      },
                      theater: {
                        only: [
                          :id, :name
                        ]
                      }
                    }
                  },
                specialization: {
                  only: :title
                },
                theater: {
                  only: :name
                },
                audition_submission: {
                  only: [:id, :video_url, :notes]
                }
              ]
            },
            rehearsals: {
              include: [
                :acts,
                :users,
                :space,
                french_scenes: {
                  methods: :pretty_name,
                  include: {
                    scene: {
                      only: [:id, :act_id]
                    }
                  }
                },
                scenes: {
                  methods:
                  :pretty_name
                }
              ]
            }
          ]
        ).merge(headshot_url: headshot_url(@user), overlap: overlap))
      else
        json_response(@user.as_json(only: [
          :id,
          :first_name,
          :last_name,
          :middle_name,
          :preferred_name,
          :program_name,
          :gender,
          :email,
          :phone_number,
          :website,
          :bio
        ]).merge(headshot_url: headshot_url(@user), overlap: overlap))
      end
    else
      return head :forbidden
    end
  end

  def create
    @user = User.create!(user_params)
    json_response(@user, :created)
  end
  def update
    authorize! :update, @user
    @user.update(user_params)
    json_response(@user)
  end

  HEADSHOT_ALLOWED_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  HEADSHOT_MAX_BYTES = 5.megabytes

  def upload_headshot
    authorize! :update, @user
    require 'marcel'
    file = params[:headshot]
    return json_response({ error: 'No file provided' }, :unprocessable_entity) unless file.present?

    actual_type = Marcel::MimeType.for(
      Pathname.new(file.path),
      name: file.original_filename,
      declared_type: file.content_type
    )
    unless HEADSHOT_ALLOWED_TYPES.include?(actual_type)
      return json_response({ error: 'Only JPEG, PNG, GIF, and WebP images are allowed' }, :unprocessable_entity)
    end

    if file.size > HEADSHOT_MAX_BYTES
      return json_response({ error: 'File must be smaller than 5 MB' }, :unprocessable_entity)
    end

    require 'aws-sdk-s3'
    ext = File.extname(file.original_filename.to_s).downcase.presence || '.jpg'
    key = "headshots/#{@user.id}/#{SecureRandom.uuid}#{ext}"
    region = ENV.fetch('AWS_REGION', 'us-east-1')
    bucket = ENV['AWS_S3_BUCKET']

    s3 = Aws::S3::Client.new(region: region)
    s3.put_object(bucket: bucket, key: key, body: file.read, content_type: actual_type)

    @user.update!(headshot_url: key)
    json_response({ headshot_url: headshot_url(@user) })
  end

  def destroy
    authorize! :destroy, @user
    @user.destroy
    head :no_content
  end

  def build_conflict_schedule
    puts "build conflict schedule called"
    set_user
    authorize! :update, @user
    conflict_schedule_pattern = params[:conflict_schedule_pattern]
    end_date = conflict_schedule_pattern[:end_date] || Date.today + 1.year
    start_date = conflict_schedule_pattern[:start_date] || Date.today
    utc_offset = conflict_schedule_pattern[:utc_offset]
    # Strip any embedded offset from display strings before storing in the pattern record
    display_start = conflict_schedule_pattern[:start_time].to_s.sub(/[+-]\d{2}:\d{2}$/, '')
    display_end   = conflict_schedule_pattern[:end_time].to_s.sub(/[+-]\d{2}:\d{2}$/, '')

    conflict_pattern = ConflictPattern.create(
      category: conflict_schedule_pattern[:category],
      days_of_week: conflict_schedule_pattern[:days_of_week],
      end_date: end_date,
      end_time: display_end,
      space_id: conflict_schedule_pattern[:space_id],
      start_date: start_date,
      start_time: display_start,
      user: @user
    )

    #order matters here, Sidekiq does not accept keyword args
    BuildConflictsScheduleWorker.perform_async(
      conflict_schedule_pattern[:category],
      conflict_pattern.id,
      conflict_schedule_pattern[:days_of_week],
      end_date,
      conflict_schedule_pattern[:end_time],
      conflict_schedule_pattern[:space_id],
      start_date,
      conflict_schedule_pattern[:start_time],
      @user.id,
      utc_offset
    )
      json_response(@user.as_json(include: [:conflicts, :conflict_patterns, :jobs]))
  end

  def fake
    @users = User.where(fake: true)
    json_response(@users.as_json(include: :jobs))
  end

  def generate_fake
    gender = params[:gender].presence || 'cis female'
    female = gender == 'cis female' || gender == 'trans female'
    male   = gender == 'cis male'   || gender == 'trans male'
    first_name =
      if female
        Faker::Name.feminine_name.split.first
      elsif male
        Faker::Name.masculine_name.split.first
      else
        Faker::Name.first_name.split.first
      end
    last_name = Faker::Name.last_name
    uid = SecureRandom.hex(4)
    user = User.create!(
      first_name: first_name,
      last_name: last_name,
      email: "#{first_name.downcase}.#{last_name.downcase}.#{uid}@fake.example",
      fake: true,
      provider: 'fake',
      gender: gender
    )
    json_response(user.as_json(include: :jobs), :created)
  end

  private

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit(
      :bio,
      :birthdate,
      :city,
      :description,
      :emergency_contact_name,
      :emergency_contact_number,
      :first_name,
      :gender,
      :email,
      :last_name,
      :middle_name,
      :phone_number,
      :preferred_name,
      :program_name,
      :state,
      :street_address,
      :timezone,
      :website,
      :zip
    )
  end

  def headshot_url(user)
    return nil unless user.headshot_url.present?
    require 'aws-sdk-s3'
    presigner = Aws::S3::Presigner.new(
      client: Aws::S3::Client.new(region: ENV.fetch('AWS_REGION', 'us-east-1'))
    )
    presigner.presigned_url(:get_object,
      bucket: ENV['AWS_S3_BUCKET'],
      key: user.headshot_url,
      expires_in: 7.days.to_i
    )
  rescue
    nil
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end
end
  end
end
