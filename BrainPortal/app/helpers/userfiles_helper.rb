
#
# CBRAIN Project
#
# Copyright (C) 2008-2012
# The Royal Institution for the Advancement of Learning
# McGill University
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#Helper methods for Userfile views.
module UserfilesHelper

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  # For display of userfile names, including:
  # type icon (collection or file), parentage icon,
  # link to show page, sync status and formats.
  def filename_listing(userfile, link_options={})
    html = []
    html << tree_view_icon(userfile.level) if @filter_params["tree_sort"] == "on" && userfile.level.to_i > 0
    if userfile.is_a? FileCollection
      file_icon = image_tag "/images/folder_icon_solid.png"
    else
      file_icon = image_tag "/images/file_icon.png"
    end
    html << ajax_link(file_icon, {:action => :index, :clear_filter => true, :find_file_id => userfile.id}, :datatype => "script", :title => "Show in Unfiltered File List")
    html << " "
    html << link_to_userfile_if_accessible(userfile, nil, link_options)
    if userfile.hidden?
      html << " "
      html << hidden_icon
    end
    if userfile.immutable?
      html << " "
      html << immutable_icon
    end

    userfile.sync_status.each do |syncstat|
      html << render(:partial => 'userfiles/syncstatus', :locals => { :syncstat => syncstat })
    end
    if userfile.formats.count > 0
      html << "<br>"
      html << ("&nbsp;" * ((userfile.level || 0) * 5))
      html << show_hide_toggle("Formats ", ".format_#{userfile.id}", :class  => "action_link")
      html << userfile.formats.map do |u|
                if u.available?
                  cb = check_box_tag("file_ids[]", u.id.to_s, false)
                else
                  cb = "<input type='checkbox' DISABLED />"
                end
                cb = "<span class=\"format_#{userfile.id}\" style=\"display:none\">#{cb}</span>"
                link_to_userfile_if_accessible(u,current_user,:name => u.format_name) + " #{cb}".html_safe
              end.join(", ")
    end
    html.join.html_safe
  end

  def neighbor_file_link(neighbor, index, dir, options = {})
    return "" unless neighbor

    if dir == :previous
      text   = "<< " + neighbor.name
    else
      text   = neighbor.name + " >>"
    end

    action       = params[:action] #Should be show or edit.
    link_options = options.delete(:html)

    link_to text, {:action  => action, :id  => neighbor.id, :sort_index => index}, link_options
  end

  def file_link_table(previous_userfile, next_userfile, sort_index, options = {})
    (
    "<div class=\"display_table\" style=\"width:100%\">" +
      "<div class=\"display_row\">" +
        "<div class=\"display_cell\">#{neighbor_file_link(previous_userfile, [0, sort_index - 1].max, :previous, options.clone)}</div>" +
        "<div class=\"display_cell\" style=\"text-align:right\">#{neighbor_file_link(next_userfile, sort_index + 1, :next, options.clone)}</div>" +
      "</div>" +
    "</div>"
    ).html_safe
  end

  # Returns HTML markup for a link to +userfile+ in a viewer's context.
  # If no link can be made, (the file is not synced, for example) a flat name
  # for the file is returned.
  # The available +options+ are the same as for viewer_userfile_url, with
  # the addition of:
  #  [:display]     Text to display on the link. Default is taken from +userfile+
  #                 if possible.
  #  [:html_target] HTML target attribute for the link. Default is '_blank', for
  #                 a new page.
  def viewer_userfile_link(userfile, options)
    display   = options.delete(:display)
    display ||= userfile.name
    display ||= Pathname.new(userfile.cache_full_path).basename.to_s if userfile.respond_to?(:cache_full_path)
    display ||= "<unknown>"
    target    = options.delete(:html_target) || "_blank"

    return h(display) unless userfile.is_locally_synced?

    link_to h(display),
      viewer_userfile_url(userfile, options),
      :target => target
  end

  # Returns a URL to +userfile+ in a viewer's context.
  # The +options+ argument can contain:
  #  [:action]       Controller action to call on the userfiles controller.
  #                  Default is :display
  #  [:page_type]    Target page to display in. Only meaningful if the :display
  #                  action is used. The possible values are 'full', for a full
  #                  page with headers (default), 'show' for within the show
  #                  page and 'bare' for a completely blank page.
  #  [:query_params] Hash of additional URL query parameters to add to the URL
  def viewer_userfile_url(userfile, options)
    # If +userfile+ is a proxy, pass on the parameters to allow the controller
    # for +action+ to re-create the proxy.
    proxy_params = userfile.proxy_parameters
      .map { |k,v| ["proxy_" + k.to_s, v] }
      .to_h
      .merge({
        :use_proxy => "true",
        :source_id => userfile.proxy_source.id,
        :file_type => userfile.class.name
      }) if userfile.is_proxy?

    url_for({
        :controller => :userfiles,
        :id         => userfile.is_proxy? ? 0 : userfile.id,
        :action     => options[:action]    || :display,
        :page_type  => options[:page_type] || :full,
      }
      .merge(proxy_params || {})
      .merge(options[:query_params] || {})
    )
  end

  # Returns HTML markup for a link to +file+ inside +collection+.
  # This method is specific to FileCollections
  def collection_file_link(collection, file)
    file_name     = file.name
    file_type     = Userfile.suggested_file_type(file_name)
    display_name  = Pathname.new(file_name).basename.to_s

    # Only link to simple files we can detect the type of
    return h(display_name) unless file_type && file_type <= SingleFile

    # Create a proxy userfile for +file+
    proxy = file_type.proxy(collection, {
      :file_name => file.name,
      :file_size => file.size
    })

    viewer_userfile_link(proxy, :display => display_name)
  end

  # Return the HTML code that represent a symbol
  # for +statkeyword+, which is a SyncStatus 'status'
  # keyword. E.g. for "InSync", the
  # HTML returned is a green checkmark, and for
  # "Corrupted" it's a red 'x'.
  def status_html_symbol(statkeyword)
    html = case statkeyword
      when "InSync"
        '<font color="green">&#10003;</font>'
      when "ProvNewer"
        '<font color="green">&lowast;</font>'
      when "CacheNewer"
        '<font color="purple">&there4;</font>'
      when "ToCache"
        '<font color="blue">&darr;</font>'
      when "ToProvider"
        '<font color="blue">&uarr;</font>'
      when "Corrupted"
        '<font color="red">&times;</font>'
      else
        '<font color="red">?</font>'
    end
    html.html_safe
  end

  #Create a collapsable "Content" box for userfiles show page.
  def content_viewer(&block)
    safe_concat('<div id="userfile_contents_display">')
    safe_concat(show_hide_toggle '<strong>Displayable Contents</strong>', "#userfile_contents_display_toggle")
    safe_concat('<div id="userfile_contents_display_toggle" style="display:none"><BR><BR>')
    safe_concat(capture(&block))
    safe_concat('</div>')
    safe_concat('</div>')
    ""
  end

  # Returned a colorized size for the userfile ; if the
  # userfile is a FileCollection, appends the number of
  # files in the collection.
  #
  #   123.4 Mb
  #   123.4 Mb (78 files)
  def colored_format_size(userfile)
    size = colored_pretty_size(userfile.size)
    size += " (#{userfile.num_files.presence || '?'} files)" if userfile.is_a?(FileCollection)
    size.html_safe
  end

end
