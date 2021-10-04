class ProductionsController < ApiController
  before_action :set_production, only: [
    :show,
    :update,
    :destroy,
    :get_production_skeleton,
    :get_production_with_play_text
  ]

  # GET /productions
  def index
    @productions = []
    if current_user.superadmin?
      @productions = Production.all
    else
      @productions = current_user.productions
    end
    json_response(@productions.as_json(include: [:play, :theater]))
  end

  # GET /productions/1
  def show
    json_response(@production.as_json(include:
        [

          :theater,
          :stage_exits,
          jobs: {
            include: [
              :specialization,
              :theater,
              :character,
              user: {
                include: :conflicts
              }
            ]
          },
          play: {
            include: :characters
          },
          rehearsals: {
            include: [:acts, :users, french_scenes: {methods: :pretty_name}, scenes: {methods: :pretty_name}]
          }
        ]
      )
    )
  end

  # POST /productions
  def create
    @production = Production.new(production_params)

    if @production.save
      json_response(@production.as_json(include: [:theater]), :created)
      PlayCopyWorker.perform_async(production_params['play_id'], @production.id)
    else
      render json: @production.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /productions/1
  def update
    if @production.update(production_params)
      json_response(@production.as_json(include:
          [
            :theater,
            :stage_exits,
            play: {
              include: [
                :characters,
                acts: {
                  include: [
                    scenes: {
                      include: [
                        french_scenes: {
                          include: [
                            entrance_exits: {
                              include: [
                                french_scene: {
                                  include: [
                                    scene: {
                                      include: :act
                                    }
                                  ]
                                  }
                                ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            jobs: {
              include: [
                :character,
                :specialization,
                :theater,
                :user
              ]
            }
          ]
        )
      )
    else
      render json: @production.errors, status: :unprocessable_entity
    end
  end

  # DELETE /productions/1
  def destroy
    @production.destroy
  end

  def production_names
    @productions = []
    if current_user.superadmin?
      @productions = Production.all
    else
      @productions = current_user.productions
    end

    render json: @productions.as_json(only: [:id, :name], include: [play: { only: [:id, :title]}, theater: { only: [:name, :id]}])
  end

  def get_productions_for_theater
    @productions = Production.where(theater: params[:theater])
    json_response(@productions.as_json(include: [play: { only: :title}, theater: { only: [:name, :id]}]))
  end

  def get_production_skeleton
    json_response(@production.as_json(include: [{theater: {only: [:id, :name]}}, {play: {only: [:id, :title]}}]))
  end

  def get_production_with_play_text
    json_response(@production.as_json(include:
        [
          :theater,
          :stage_exits,
          rehearsals: {
            include: [
              :users,
              acts: {methods: :on_stages},
              french_scenes: {
                include: [:on_stages],
                methods: :pretty_name
              },
              scenes: {methods: [:on_stages, :pretty_name]}]
          },
          play: {
            include: [
              characters: {
                include: :lines
              },
              acts: {
                include: [
                  scenes: {
                    include: [
                      french_scenes: {
                        include: [
                            on_stages: {
                              include: :character
                            },
                            entrance_exits: {
                          #   include: [
                          #     french_scene: {
                          #       include: [
                          #         scene: {
                          #           include: :act
                          #         }
                          #       ]
                          #       }
                          #     ]
                        },
                      ],
                        methods: :pretty_name
                      }
                    ],
                    methods: :pretty_name
                  }
                ]
              }
            ]
          },
          jobs: {
            include: [
              :specialization,
              :theater,
              user: {
                include: :conflicts
              },
              character: {
                include: :lines
              }
            ]
          }
        ]
      )
    )
  end

  def build_rehearsal_schedule
    set_production
    json_response(@production.as_json(include: [:theater]))
    rehearsal_schedule_pattern = params[:production][:rehearsal_schedule_pattern]
    BuildRehearsalScheduleWorker.perform_async(
      rehearsal_schedule_pattern[:break_length],
      rehearsal_schedule_pattern[:days_of_week],
      rehearsal_schedule_pattern[:default_user_ids],
      rehearsal_schedule_pattern[:end_date],
      rehearsal_schedule_pattern[:end_time],
      @production.id,
      rehearsal_schedule_pattern[:time_between_breaks],
      rehearsal_schedule_pattern[:start_date],
      rehearsal_schedule_pattern[:start_time]
    )
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_production
      @production = Production.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def production_params
      params.require(:production).permit(
        :end_date,
        :id,
        :lines_per_minute,
        :play_id,
        :rehearsal_block_length,
        :rehearsal_break_length,
        :rehearsal_days_of_week,
        :rehearsal_default_user_ids,
        :rehearsal_end_date,
        :rehearsal_end_time,
        :rehearsal_start_date,
        :rehearsal_end_time,
        :rehearsal_time_between_breaks,
        :theater_id,
        :start_date,
      )
    end
end
