class ShowsController < ApplicationController
  def index
    @shows = Show.order(id: :desc)
  end

  def show
    @show = Show.find(params[:id])
  end
end