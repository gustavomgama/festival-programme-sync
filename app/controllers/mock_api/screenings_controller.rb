module MockApi
  class ScreeningsController < ActionController::API
    def index
      sleep 6 if truthy?(params[:slow])

      all    = Dataset.records(generation: params.fetch(:generation, 1))
      page   = [ params.fetch(:page, 1).to_i, 1 ].max
      offset = (page - 1) * Dataset::PER_PAGE

      fail_after = params[:fail_after].presence&.to_i

      if fail_after && offset >= fail_after
        return render json: { error: "Upstream festival system unavailable" },
                      status: :internal_server_error
      end

      slice = all[offset, Dataset::PER_PAGE] || []

      if fail_after
        allowed = [ fail_after - offset, 0 ].max
        slice   = slice.first(allowed)
      end

      render json: {
        page:        page,
        per_page:    Dataset::PER_PAGE,
        total_pages: (all.size.to_f / Dataset::PER_PAGE).ceil,
        total_count: all.size,
        screenings:  slice
      }
    end

    private

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
