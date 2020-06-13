class HealthcheckController < ApplicationController
  def check
    render plain: 'OK'
  end
end
