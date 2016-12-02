# require 'test_helper'
#
# class LogEventsControllerTest < ActionController::TestCase
#   setup do
#     @log_event = log_events(:one)
#   end
#
#   test "should get index" do
#     get :index
#     assert_response :success
#     assert_not_nil assigns(:log_events)
#   end
#
#   test "should get new" do
#     get :new
#     assert_response :success
#   end
#
#   test "should create log_event" do
#     assert_difference('LogEvent.count') do
#       post :create, log_event: { ack_comment: @log_event.ack_comment, acknowledged_by: @log_event.acknowledged_by, acknowledged_on: @log_event.acknowledged_on, application_name: @log_event.application_name, hostname: @log_event.hostname, level: @log_event.level, message: @log_event.message, tag: @log_event.tag }
#     end
#
#     assert_redirected_to log_event_path(assigns(:log_event))
#   end
#
#   test "should show log_event" do
#     get :show, id: @log_event
#     assert_response :success
#   end
#
#   test "should get edit" do
#     get :edit, id: @log_event
#     assert_response :success
#   end
#
#   test "should update log_event" do
#     patch :update, id: @log_event, log_event: { ack_comment: @log_event.ack_comment, acknowledged_by: @log_event.acknowledged_by, acknowledged_on: @log_event.acknowledged_on, application_name: @log_event.application_name, hostname: @log_event.hostname, level: @log_event.level, message: @log_event.message, tag: @log_event.tag }
#     assert_redirected_to log_event_path(assigns(:log_event))
#   end
#
#   test "should destroy log_event" do
#     assert_difference('LogEvent.count', -1) do
#       delete :destroy, id: @log_event
#     end
#
#     assert_redirected_to log_events_path
#   end
# end
