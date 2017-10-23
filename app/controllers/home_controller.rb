class HomeController < ApplicationController

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
      # notes = notes.joins(:url_entries)
      notes = notes.where("plainto_tsquery('english', ?) @@ to_tsvector('english', notes.text)", params[:string])
      # notes = notes.joins(:url_entries).where(UrlEntry.arel_table[:url].contains(params[:string].split))
      # note = note.or(notes.joins(:url_entries).where)
      urls = UrlEntry.all
      params[:string].split.each do |word|
        urls = UrlEntry.where(UrlEntry.arel_table[:url].lower.matches("%#{word.downcase}%"))
      end
      notes = notes.or(Note.where(id: urls.distinct.pluck(:note_id)))
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

    count = notes.count

    page = [1, params[:page].to_i].max
    notes = notes.order(show_id: :desc).offset((page-1) * 20).limit(20)

    render json: {
      count: count,
      page: page,
      page_count: (count / 20) + 1,
      results: notes.map do |note|
        note.slice(:show_id, :title, :topic)
            .merge(text: note.truncate_text)
      end
    }
  end
end