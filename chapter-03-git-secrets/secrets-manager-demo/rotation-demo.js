/**
 * Secret Rotation Pattern
 * 
 * Applications must be designed to handle secret rotation
 * without downtime. This requires:
 * 1. Never caching secrets indefinitely
 * 2. Handling authentication failures by refreshing the secret
 * 3. Designing connection pools to reconnect with new credentials
 */

// Simulated secret that will "rotate" after a few reads
let rotationCount = 0;
const secretVersions = {
  0: { password: 'initial_password_v1', version: 'AWSCURRENT' },
  1: { password: 'rotated_password_v2', version: 'AWSCURRENT' },
  2: { password: 'rotated_password_v3', version: 'AWSCURRENT' }
};

async function getSecretWithRotation(secretName) {
  const version = Math.min(rotationCount, 2);
  return secretVersions[version];
}

async function connectToDatabase(secret) {
  console.log(`[DB] Connecting with password version: ${secret.version}`);
  
  // Simulate connection failure when password is stale
  if (rotationCount > 0 && secret.password === secretVersions[0].password) {
    throw new Error('Authentication failed - password may have rotated');
  }
  
  console.log('[DB] Connection successful');
  return { connected: true };
}

// Pattern: retry with refreshed secret on auth failure
async function connectWithRetry(secretName) {
  let secret = await getSecretWithRotation(secretName);
  
  try {
    return await connectToDatabase(secret);
  } catch (error) {
    if (error.message.includes('Authentication failed')) {
      console.log('[App] Auth failed - refreshing secret and retrying');
      rotationCount++;
      secret = await getSecretWithRotation(secretName);
      return await connectToDatabase(secret);
    }
    throw error;
  }
}

async function runDemo() {
  console.log('=== Secret Rotation Demo ===\n');
  
  console.log('Attempt 1 - Initial connection:');
  await connectWithRetry('workstream/production/database');
  
  console.log('\nSimulating secret rotation...');
  rotationCount++;
  
  console.log('\nAttempt 2 - After rotation (with retry logic):');
  await connectWithRetry('workstream/production/database');
  
  console.log('\n[Result] Application handled secret rotation without downtime');
}

runDemo().catch(console.error);
