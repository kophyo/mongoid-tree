module Mongoid
  module Tree
    ##
    # TODO: Write a little documentation.
    module Ordering
      extend ActiveSupport::Concern

      included do
        reflect_on_association(:children).options[:default_order] = :position.asc

        field :position, :type => Integer

        after_rearrange :assign_default_position
      end

      ##
      # Returns siblings below the current document.
      # Siblings with a position greater than this documents's position.
      def lower_siblings
        self.siblings.where(:position.gt => self.position)
      end

      ##
      # Returns siblings above the current document.
      # Siblings with a position lower than this documents's position.
      def higher_siblings
        self.siblings.where(:position.lt => self.position)
      end

      ##
      # Returns the lowest sibling (could be self)
      def last_sibling_in_list
        siblings_and_self.asc(:position).last
      end

      ##
      # Returns the highest sibling (could be self)
      def first_sibling_in_list
        siblings_and_self.asc(:position).first
      end

      ##
      # Is this the highest sibling?
      def at_top?
        higher_siblings.empty?
      end

      ##
      # Is this the lowest sibling?
      def at_bottom?
        lower_siblings.empty?
      end

      ##
      # Move this node above all its siblings
      def move_to_top
        return true if at_top?
        move_above(first_sibling_in_list)
      end

      ##
      # Move this node below all its siblings
      def move_to_bottom
        return true if at_bottom?
        move_below(last_sibling_in_list)
      end

      ##
      # Move this node one position up
      def move_up
        return if at_top?
        siblings.where(:position => self.position - 1).first.inc(:position, 1)
        inc(:position, -1)
      end

      ##
      # Move this node one position down
      def move_down
        return if at_bottom?
        siblings.where(:position => self.position + 1).first.inc(:position, -1)
        inc(:position, 1)
      end

      ##
      # Move this node above the specified node
      #
      # This method changes the node's parent if nescessary.
      def move_above(other)
        move_to_parent_of(other) unless sibling_of?(other)

        if position > other.position
          new_position = other.position
          other.lower_siblings.each { |s| s.inc(:position, 1) }
          other.inc(:position, 1)
          update_attributes!(:position => new_position)
        else
          new_position = other.position - 1
          other.higher_siblings.each { |s| s.inc(:position, -1) }
          update_attributes!(:position => new_position)
        end
      end

      ##
      # Move this node below the specified node
      #
      # This method changes the node's parent if nescessary.
      def move_below(other)
        move_to_parent_of(other) unless sibling_of?(other)

        if position > other.position
          new_position = other.position + 1
          other.lower_siblings.each { |s| s.inc(:position, 1) }
          update_attributes!(:position => new_position)
        else
          new_position = other.position
          other.higher_siblings.each { |s| s.inc(:position, -1) }
          other.inc(:position, -1)
          update_attributes!(:position => new_position)
        end
      end

    private
      def move_to_parent_of(other)
        lower_siblings.each { |s| s.inc(:position, -1) }
        update_attributes!(:parent_id => other.parent_id)
      end

      def assign_default_position
        return unless self.position.nil? || self.parent_id_changed?

        if self.siblings.empty? || self.siblings.collect(&:position).compact.empty?
          self.position = 0
        else
          self.position = self.siblings.max(:position) + 1
        end
      end
    end # Ordering
  end # Tree
end # Mongoid
