class QuoteAuthorizationsController < ApplicationController
  before_action :set_quote, only: %i[ show ]

  def show
    if @quote&.quoted_status&.local? && @quote.accepted?
      render json: @quote, serializer: QuoteAuthorizationSerializer, content_type: 'application/activity+json'
    else
      render json: {}
    end
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end
end
