class Api::V1::Timelines::PublicController < ApplicationController
  def show
    render json: {}, status: 200
  end
end
