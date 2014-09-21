class MachinesController < ApplicationController
  before_action :authenticate_user!

  include FindMachine
  find_machine_before_action :id, except: [:index, :new, :create]


  def index
    @machines = current_user.machines
  end

  def new
    @machine ||= Forms::NewMachine.new
    @plans ||= Defaults::MachinePlan.all
    @isos ||= Plans::IsoDistro.all
  end

  def create
    machine_params = Forms::NewMachine.check_params params, current_user
    @machine = Forms::NewMachine.new machine_params

    handle_errors :new_machine do
      if created = @machine.save
        redirect_to created
        return
      end
    end

    new
    render 'new'
  end

  def show
    @disk_types = Infra::DiskType.all
    @disk = Infra::Disk.new
    @iso_images = Plans::IsoImage.all
  end

  def destroy
    @meta_machine.delete
    @machine.delete
    redirect_to machines_path
  end

  %w(start pause resume stop force_stop restart force_restart).each do |operation|
    define_method operation do
      handle_errors :power do
        @machine.send operation
      end
      redirect_to machine_path @machine, anchor: 'power'
    end
  end

  def mount_iso
    iso_image = Plans::IsoImage.find params[:machine][:iso_image_id]
    @machine.mount_iso iso_image
    redirect_to machine_path @machine, anchor: 'settings'
  end
end
