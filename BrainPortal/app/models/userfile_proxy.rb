
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

class Userfile #:nodoc:

  # Userfile added behavior to create temporary proxy userfiles used for
  # special viewing purposes.
  module Proxy

    Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

    def self.included(includer) #:nodoc:
      includer.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods

      # Create a new proxy userfile bound to +source+ using
      # +proxy_parameters+ with attributes +attributes+.
      # The proxy will have the source userfile available and the
      # creation parameters available in the 'proxy_source' and
      # 'proxy_parameters' instance attributes, respectively.
      def proxy(source, proxy_parameters, attributes = {})
        # Create the proxy and make it transient (not save-able)
        userfile = self.new(attributes)
        userfile.transient!

        # Void access to the proxy's DP methods, as they do not apply to
        # proxies. They may be re-added by the proxy's source, if a sensible
        # behavior exists.
        userfile.singleton_class.class_eval do
          [ :allow_file_owner_change?,
            :sync_to_cache,
            :sync_to_provider,
            :cache_prepare,
            :cache_full_path,
            :cache_readhandle,
            :cache_writehandle,
            :cache_copy_from_local_file,
            :cache_copy_to_local_file,
            :cache_erase,
            :cache_collection_index,
            :provider_erase,
            :provider_rename,
            :provider_move_to_otherprovider,
            :provider_copy_to_otherprovider,
            :provider_collection_index,
            :provider_readhandle,
            :provider_full_path,
            :available?
          ].each { |m| undef_method(m) }
        end

        # The proxy's sync status corresponds to the source's
        [ :provider_is_newer,
          :cache_is_newer,
          :local_sync_status,
          :is_locally_synced?,
          :is_locally_cached?
        ].each do |m|
          userfile.define_singleton_method(m) { |*args| source.send(m, *args) }
        end

        # Bind the proxy to its source
        userfile.define_singleton_method(:proxy_source)     { source }
        userfile.define_singleton_method(:proxy_parameters) { proxy_parameters.clone }
        source.bind_as_proxy(userfile, proxy_parameters) if source.respond_to?(:bind_as_proxy)

        userfile
      end
    end

    # Is this userfile a proxy for another?
    def is_proxy?
      respond_to?(:proxy_source) && proxy_source
    end
  end

  include Proxy
end
