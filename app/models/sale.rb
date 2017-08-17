class Sale < ApplicationRecord
	before_create :populate_uuid

	belongs_to :experience
	has_many   :reviews
	

	include AASM

		aasm column: 'state' do
			state :pending, initial: true
			state :processing
			state :finished
			state :failure

			event :process, after: :charge_card do
				transitions from: :pending, to: :processing
			end

			event :finish do
				transitions from: :processing, to: :finished
				
			end

			event :fail do
				transitions from: :processing, to: :failure
			end

		end

	def charge_card
		begin
			save!
			
			seller = User.find_by(email: self.seller_email)
			buyer = User.find_by(email: self.buyer_email)
			experience = Experience.find_by(id: self.exp_id)
			logger.debug " Seller Stripe Cust Uid: #{seller.uid}"
			charge = Stripe::Charge.create(
				amount: self.amount * 100,
				currency: "usd",
				card: self.stripe_token,
				description: experience.exp_name,
				destination: {
					amount: self.amount * 80, # 80% of the total amount goes to the Host
					account: seller.uid
				} )

			self.update(stripe_id: charge.id)

			logger.debug "Strip Charge: #{charge}"

			self.finish!

			#Create notification for Seller
			create_notification(buyer, seller)

		rescue Stripe::StripeError => e
			self.update_attributes(error: e.message)
			self.fail!
		end
	end


	private

		def populate_uuid
			self.uuid  = SecureRandom.uuid()
		end

		def create_notification(guest, seller)
	      type =  "New Booking" 
	   
	      Notification.create(content: "#{type} from #{guest.first_name}  #{guest.last_name}", user_id: seller.id)
	    end
	
end
