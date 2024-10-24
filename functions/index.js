const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
admin.initializeApp();

async function updatePendingLogsAndPostsLogic() {
  const db = admin.firestore();

  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayDateString = today.toISOString().split('T')[0];

  console.log(`Current Date: ${todayDateString}`);

  try {
    const recurringPostsRef = db.collection('recurring');
    const recurringPostsSnapshot = await recurringPostsRef.where('current', '==', true).get();

    console.log(`Found ${recurringPostsSnapshot.size} recurring posts to process.`);

    if (recurringPostsSnapshot.empty) {
      console.log('No recurring posts with current=true found.');
    }

    for (const postDoc of recurringPostsSnapshot.docs) {
      const postData = postDoc.data();
      console.log(`Processing recurring post ID: ${postDoc.id}`);

      if (!postData.end_date || !postData.start_date || !postData.accepted_volunteers || !postData.schedule) {
        console.log(`Post ID: ${postDoc.id} is missing required fields.`);
        continue;
      }

      const endDate = postData.end_date.toDate ? postData.end_date.toDate() : new Date(postData.end_date);
      const startDate = postData.start_date.toDate ? postData.start_date.toDate() : new Date(postData.start_date);

      const normalizedEndDate = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate());
      const normalizedStartDate = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());

      const endDateStr = normalizedEndDate.toISOString().split('T')[0];
      console.log(`End Date: ${endDateStr}`);

      if (normalizedEndDate <= today) {
        console.log(`End date is today or past. Processing post ID: ${postDoc.id}`);

        await postDoc.ref.update({ current: false });
        console.log(`Set 'current' to false for post ID: ${postDoc.id}`);

        let dates = [];
        let dt = new Date(normalizedStartDate);

        const schedule = postData.schedule; 
        const scheduledDays = Object.keys(schedule).filter(day => schedule[day]);
        console.log(`Scheduled Days: ${scheduledDays.join(', ')}`);

        const getDayName = (date) => {
          return date.toLocaleDateString('en-US', { weekday: 'long' });
        };

        while (dt <= normalizedEndDate) {
          const dayName = getDayName(dt);
          if (scheduledDays.includes(dayName)) {
            dates.push(dt.toISOString().split('T')[0]);
          }
          dt.setDate(dt.getDate() + 1);
        }

        console.log(`Generated dates for post ID ${postDoc.id} based on schedule:`, dates);

        const acceptedVolunteers = postData.accepted_volunteers || [];
        console.log(`Found ${acceptedVolunteers.length} accepted volunteers for post ID: ${postDoc.id}`);

        for (const volunteer of acceptedVolunteers) {
          for (const userId in volunteer) {
            console.log(`Updating pending_logs for user ID: ${userId}`);
            const userRef = db.collection('users').doc(userId);
            const userDoc = await userRef.get();
            if (userDoc.exists) {
              const userData = userDoc.data();
              let pendingLogs = userData.pending_logs || [];

              let existingLog = pendingLogs.find(pl => pl.post_id === postDoc.id);
              if (existingLog) {
                existingLog.dates = Array.from(new Set([...existingLog.dates, ...dates]));
                console.log(`Merged dates for user ID: ${userId}, post ID: ${postDoc.id}`);
              } else {
                pendingLogs.push({ post_id: postDoc.id, dates: dates });
                console.log(`Added new pending_logs entry for user ID: ${userId}, post ID: ${postDoc.id}`);
              }

              await userRef.update({ pending_logs: pendingLogs });
              console.log(`Updated pending_logs for user ID: ${userId}`);
            } else {
              console.log(`User document does not exist for user ID: ${userId}`);
            }
          }
        }
      } else {
        console.log(`End date (${endDateStr}) is in the future. Skipping post ID: ${postDoc.id}`);
      }
    }

    const nonRecurringPostsRef = db.collection('non_recurring');
    const nonRecurringPostsSnapshot = await nonRecurringPostsRef.where('current', '==', true).get();

    console.log(`Found ${nonRecurringPostsSnapshot.size} non-recurring posts to process.`);

    for (const postDoc of nonRecurringPostsSnapshot.docs) {
      const postData = postDoc.data();
      const startDate = postData.start_date.toDate ? postData.start_date.toDate() : new Date(postData.start_date);
      const normalizedStartDate = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
      const startDateStr = normalizedStartDate.toISOString().split('T')[0];

      console.log(`Processing non-recurring post ID: ${postDoc.id}, Start Date: ${startDateStr}`);

      if (normalizedStartDate <= today) {
        console.log(`Start date is today or past. Processing post ID: ${postDoc.id}`);

        await postDoc.ref.update({ current: false });
        console.log(`Set 'current' to false for post ID: ${postDoc.id}`);

        const dateStr = startDateStr;

        const acceptedVolunteers = postData.accepted_volunteers || [];
        console.log(`Found ${acceptedVolunteers.length} accepted volunteers for post ID: ${postDoc.id}`);

        for (const volunteer of acceptedVolunteers) {
          for (const userId in volunteer) {
            console.log(`Updating pending_logs for user ID: ${userId}`);
            const userRef = db.collection('users').doc(userId);
            const userDoc = await userRef.get();
            if (userDoc.exists) {
              const userData = userDoc.data();
              let pendingLogs = userData.pending_logs || [];

              let existingLog = pendingLogs.find(pl => pl.post_id === postDoc.id);
              if (existingLog) {
                if (!existingLog.dates.includes(dateStr)) {
                  existingLog.dates.push(dateStr);
                  console.log(`Added date ${dateStr} to existing pending_logs for user ID: ${userId}`);
                }
              } else {
-                pendingLogs.push({ post_id: postDoc.id, dates: [dateStr] });
                console.log(`Added new pending_logs entry for user ID: ${userId}, post ID: ${postDoc.id}`);
              }

              await userRef.update({ pending_logs: pendingLogs });
              console.log(`Updated pending_logs for user ID: ${userId}`);
            } else {
              console.log(`User document does not exist for user ID: ${userId}`);
            }
          }
        }
      } else {
        console.log(`Start date (${startDateStr}) is in the future. Skipping post ID: ${postDoc.id}`);
      }
    }

    console.log('Pending logs and posts updated successfully.');
  } catch (error) {
    console.error('Error updating pending logs and posts:', error);
    throw error;
  }
}

exports.updatePendingLogsAndPosts = onSchedule('every day 00:00', async (event) => {
  console.log('Function triggered: updatePendingLogsAndPosts');
  await updatePendingLogsAndPostsLogic();
});

exports.testUpdatePendingLogsAndPosts = onRequest(async (req, res) => {
  try {
    await updatePendingLogsAndPostsLogic();
    res.status(200).send('Function executed successfully.');
  } catch (error) {
    console.error('Error during test invocation:', error);
    res.status(500).send('Function execution failed.');
  }
});
