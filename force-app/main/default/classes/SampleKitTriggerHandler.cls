public class SampleKitTriggerHandler {

	public static void handleBeforeInsert(List<Sample_Kit__c> sampleKits) {
		SampleKitServices.updateSubmitter(sampleKits);
        SampleKitServices.setTrackingNumberCreationDateOnInsert(sampleKits);
        SampleKitServices.setCasetoSampleKitOnInsert(sampleKits);
	}


	public static void handleBeforeUpdate(List<Sample_Kit__c> sampleKits, Map<Id, Sample_Kit__c> oldSampleKits) {
		SampleKitServices.updateRelatedCaseWhenSampleKitIsShipped(sampleKits, oldSampleKits);
		SampleKitServices.updateSubmitter(sampleKits);
        SampleKitServices.setTrackingNumberCreationDateOnUpdate(sampleKits, oldSampleKits);
	}
	/*
		public static void handleBeforeDelete(List<Sample_Kit__c> sampleKits, Map<Id, Sample_Kit__c> oldSampleKits) {
		}

		public static void handleAfterInsert(List<Sample_Kit__c> sampleKits, Map<Id, Sample_Kit__c> oldSampleKits) {
		}
		public static void handleAfterUpdate(List<Sample_Kit__c> sampleKits, Map<Id, Sample_Kit__c> oldSampleKits) {
		}
		*/


}