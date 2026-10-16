class SyncRun < ApplicationRecord
  validates :status, presence: true

  def running? = status == "running"
  def succeeded? = status == "success"
  def partially_failed? = status == "partial_failure"
  def failed? = status == "failed"
  def records_skipped = records_unchanged
  def skipped = records_unchanged
end
