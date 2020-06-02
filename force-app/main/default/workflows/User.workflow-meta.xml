<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Access_Group</fullName>
        <field>Access_Group__c</field>
        <formula>IF ( 
Profile.Name = &quot;International Distributor Community&quot;, &quot;EXTINTL&quot;, 

IF ( 
Profile.Name = &quot;Distributor Community Plus&quot;, &quot;EXTERNAL&quot;,

IF ( 
Profile.Name = &quot;Distributor Community&quot;, &quot;EXTERNAL&quot;, 

IF ( 
Profile.Name = &quot;Vendor Community&quot;, &quot;EXTERNAL&quot;,  

IF( 
Profile.Name = &quot;Company Employee&quot;, &quot;EMPLOYEE&quot;, 

CASE( UserRole.Name, 
null, &quot;EXTERNAL&quot;, 
&quot;GBS HR Analyst&quot;,&quot;HR&quot;, 
&quot;GBS HR Management&quot;,&quot;HR&quot;, 
&quot;GBS Payroll Analyst&quot;,&quot;PAYROLL&quot;, 
&quot;GBS Payroll Management&quot;,&quot;PAYROLL&quot;, 
&quot;Customer Service Management&quot;,&quot;CS&quot;, 
&quot;Customer Service Coordinator&quot;,&quot;CS&quot;, 
&quot;Application Admin&quot;,&quot;ADMIN&quot;, 
&quot;EMPLOYEE&quot; 
) 
) 
) 
)
)
)</formula>
        <name>Set Access Group</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Access Group</fullName>
        <actions>
            <name>Set_Access_Group</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Field update that sets the Access Group field on a User; the Access Group field is used by the GBS and CS Community flows to govern the visibility of categories in the Case flows</description>
        <formula>ISNEW() || 
ISCHANGED( UserRoleId ) || 
ISCHANGED( ProfileId ) || 
ISBLANK( Access_Group__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
