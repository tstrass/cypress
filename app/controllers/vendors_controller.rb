require 'api'

class VendorsController < ApplicationController
  include API::Controller
  before_action :set_vendor, only: [:show, :update, :destroy, :edit, :favorite]
  before_action :authorize_vendor, only: [:show, :update, :destroy, :edit, :favorite]

  # breadcrumbs
  add_breadcrumb 'Dashboard', :vendors_path
  add_breadcrumb 'Add Vendor', :new_vendor_path, only: [:new, :create]

  respond_to :js, only: [:show, :favorite]

  def index
    # get all of the vendors that the user can see
    @vendors = Vendor.accessible_by(current_user).order(:updated_at => :desc) # Vendor.accessible_by(current_user).all.order(:updated_at => :desc)
    @vendors = @vendors.sort_by { |a| a.favorite ? 0 : 1 }
    respond_with(@vendors.to_a)
  end

  def show
    add_breadcrumb 'Vendor: ' + @vendor.name, :vendor_path
    product_arr = Product.where(vendor_id: @vendor.id).order_by(state: 'desc').sort_by { |a| a.favorite ? 0 : 1 }
    @products = Kaminari.paginate_array(product_arr).page(params[:page]).per(5)
    respond_with(@vendor)
  end

  def new
    authorize! :create, Vendor.new
    @vendor = Vendor.new
  end

  def create
    authorize! :create, Vendor.new
    @vendor = Vendor.new(vendor_params)
    @vendor.save!
    current_user.add_role :owner, @vendor
    flash_comment(@vendor.name, 'success', 'created')
    respond_with(@vendor) do |f|
      f.html { redirect_to root_path }
    end
  rescue Mongoid::Errors::Validations
    respond_with_errors(@vendor) do |f|
      f.html { render :new, :status => :bad_request }
    end
  end

  def edit
    add_breadcrumb 'Vendor: ' + @vendor.name, :vendor_path
    add_breadcrumb 'Edit Vendor', :edit_vendor_path
  end

  def update
    add_breadcrumb 'Vendor: ' + @vendor.name, :vendor_path
    add_breadcrumb 'Edit Vendor', :edit_vendor_path
    @vendor.update_attributes(vendor_params)
    @vendor.save!
    flash_comment(@vendor.name, 'info', 'edited')
    respond_with(@vendor) do |f|
      f.html { redirect_to root_path }
    end
  rescue Mongoid::Errors::Validations
    respond_with_errors(@vendor) do |f|
      f.html { render :edit, :status => :bad_request }
    end
  end

  def destroy
    @vendor.destroy
    flash_comment(@vendor.name, 'danger', 'removed')
    respond_with(@vendor) do |f|
      f.html { redirect_to root_path }
    end
  end

  def favorite
    @vendor.favorite = !@vendor.favorite
    @vendor.save!
    @vendors = Vendor.accessible_by(current_user).order(:updated_at => :desc)
    @vendors = @vendors.sort_by { |a| a.favorite ? 0 : 1 }
    respond_with(@vendors.to_a) do |f|
      f.js {}
    end
  end

  private

  def authorize_vendor
    authorize_request(@vendor)
  end

  def vendor_params
    params[:vendor][:name].strip! if params[:vendor][:name]
    params.require(:vendor).permit(:name, :vendor_id, :url, :address, :state, :zip,
                                   points_of_contact_attributes: [:id, :name, :email, :phone, :contact_type, :_destroy])
  end
end
