/// Seed data for browsing roleplay scenarios by category (Prompt 9,
/// section 3). The learner can also skip this entirely and type a
/// custom request — see RoleplayService.generateScenario.
const Map<String, List<String>> kRoleplayCategories = {
  'Daily Life': [
    'Meeting someone new',
    'Making weekend plans',
    'Declining an invitation politely',
    'Asking a neighbor for help',
  ],
  'Travel': [
    'Hotel check-in with a booking problem',
    'Flight delay at the airport',
    'Asking for directions',
    'Lost luggage at the airport',
  ],
  'Shopping': [
    'Asking for a discount',
    'Returning a faulty product',
    'Comparing two products with a salesperson',
  ],
  'Restaurant': [
    'Ordering food with dietary restrictions',
    'Complaining about a wrong order',
    'Making a reservation by phone',
  ],
  'Workplace': [
    'Giving a status update to your manager',
    'Requesting time off',
    'Handling a disagreement with a colleague',
    'Daily stand-up meeting',
  ],
  'Sales': [
    'Cold approach call',
    'Handling a price objection',
    'Following up after a proposal',
    'Closing a hesitant client',
  ],
  'Business': [
    'Partnership negotiation',
    'Pricing discussion with a distributor',
    'Presenting a proposal to stakeholders',
  ],
  'Interview': [
    'HR interview — tell me about yourself',
    'Behavioral interview — a challenge you faced',
    'Salary negotiation',
    'Explaining a gap in your resume',
  ],
  'Phone Call': [
    'Customer service complaint call',
    'Scheduling an appointment',
    'Confirming an order over the phone',
  ],
  'Social': [
    'Networking at an event',
    'Casual small talk with a new colleague',
    'Catching up with an old friend',
  ],
  'Academic': [
    'Explaining an idea in a group project',
    'Asking a professor a question after class',
  ],
  'Advanced': [
    'Debate: should companies allow fully remote work?',
    'Crisis communication with an unhappy client',
    'Executive negotiation under time pressure',
  ],
};
