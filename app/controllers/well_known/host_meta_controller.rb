class WellKnown::HostMetaController < ApplicationController
  def show
    if request.format.json?
      render json: { links: [{ rel: 'lrdd', template: lrdd_template }] }, content_type: 'application/json'
    else
      render body: xrd, content_type: 'application/xrd+xml'
    end
  end

  private

  def lrdd_template
    "#{webfinger_url}?resource={uri}"
  end

  def xrd
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
        <Link rel="lrdd" template="#{ERB::Util.html_escape(lrdd_template)}"/>
      </XRD>
    XML
  end
end
