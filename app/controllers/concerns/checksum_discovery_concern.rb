module ChecksumDiscoveryConcern
  # extend ActiveSupport::Concern

  def active_subsets
    TerminologyConfig.subset_gui
  end
end
