class HomeController < ApplicationController

  PAGE_SIZE = 21

  def index
    @min_show = Show.order(:id).pluck(:id).first
    @max_show = Show.order(id: :desc).pluck(:id).first
  end

  def topics
    render json: Note.distinct.pluck(:topic)
  end

  def search
    t = Note.arel_table
    notes = Note.all

    unless params[:string].blank?
      terms = params[:string].remove('\'')
      notes = notes.where("plainto_tsquery('english', ?) @@ to_tsvector('english', notes.document)", terms)
    end
    if (min = params[:min_show].to_i) > 0
      notes = notes.where(t[:show_id].gteq min)
    end
    if (max = params[:max_show].to_i) > 0
      notes = notes.where(t[:show_id].lteq max)
    end
    unless params[:topics].blank?
      notes = notes.where(topic: params[:topics])
    end

    page  = [1, params[:page].to_i].max
    count = page == 1 ? notes.count : nil
    notes = notes
              .order(show_id: :desc)
              .offset((page-1) * PAGE_SIZE)
              .first(PAGE_SIZE)

    render json: {
      count:    count,
      page:     page,
      has_more: notes.length == PAGE_SIZE,
      results:  notes.first(PAGE_SIZE - 1)
    }
  end
end