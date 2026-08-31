enum BagProcessId {
  emptyBagCollected         ('1', 'Empty Bag Collected'),
  bagOpenedByPhlebotomist   ('2', 'Bag Opened by Phlebotomist'),
  bagClosedByPhlebotomist   ('3', 'Bag Closed by Phlebotomist'),
  samplesTransferred        ('4', 'Samples Transferred to Destination Bag'),
  wholeBagCollected         ('5', 'Whole Sample Bag Collected'),
  bagHandover               ('6', 'Bag Handover'),
  bagSubmittedToLab         ('7', 'Bag Submitted to Lab'),
  bagAcceptedByLab          ('8', 'Bag Accepted by Lab Technician'),
  endBagSession             ('100', 'Bag Submit to Lab by Phlebotomist');

  const BagProcessId(this.processId, this.label);

  final String processId;
  final String label;
}

/*

Event master
1) Empty bag collected by RB or Connector (Destination Bag purpose only)
2) Open bag by Phelebo
3) Close bag by Phelebo
4) Transfer samples from Phelbo bag to destination bag by RB or Connector
5) whole Sample Bag of Phelbo collected  by RB or Connector
6) Sample bag handover by RB/ connector to connector/ Rb
7) Bag Submitted to lab by RB/ Connector
8) Bag Accepted by lab technician


*/
