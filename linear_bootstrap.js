#!/usr/bin/env node

/**
 * Linear Bootstrap Script
 * Creates team, labels, project, and initial issues in Linear using GraphQL API.
 */

const LINEAR_API_URL = 'https://api.linear.app/graphql';

class LinearBootstrap {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.headers = {
      'Authorization': apiKey,
      'Content-Type': 'application/json',
    };
  }

  async query(query, variables = null) {
    const payload = { query };
    if (variables) {
      payload.variables = variables;
    }

    const response = await fetch(LINEAR_API_URL, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`GraphQL request failed: ${response.status} - ${text}`);
    }

    const result = await response.json();
    if (result.errors) {
      throw new Error(`GraphQL errors: ${JSON.stringify(result.errors)}`);
    }

    return result.data || {};
  }

  async getOrCreateTeam(teamName) {
    // Query for existing team
    const query = `
      query Teams {
        teams {
          nodes {
            id
            name
            key
          }
        }
      }
    `;

    const data = await this.query(query);
    const teams = data.teams?.nodes || [];

    for (const team of teams) {
      if (team.name === teamName) {
        console.log(`✓ Team '${teamName}' already exists (ID: ${team.id}, Key: ${team.key})`);
        return team;
      }
    }

    // Create team if it doesn't exist
    const mutation = `
      mutation CreateTeam($name: String!, $key: String!) {
        teamCreate(input: {name: $name, key: $key}) {
          success
          team {
            id
            name
            key
          }
        }
      }
    `;

    const variables = {
      name: teamName,
      key: 'ACP', // Team key for Agent-Control-Plane
    };

    const result = await this.query(mutation, variables);
    const team = result.teamCreate.team;
    console.log(`✓ Created team '${teamName}' (ID: ${team.id}, Key: ${team.key})`);
    return team;
  }

  async getOrCreateLabel(teamId, labelName) {
    // Query for existing labels
    const query = `
      query Labels($teamId: String!) {
        team(id: $teamId) {
          labels {
            nodes {
              id
              name
            }
          }
        }
      }
    `;

    const data = await this.query(query, { teamId });
    const labels = data.team?.labels?.nodes || [];

    for (const label of labels) {
      if (label.name === labelName) {
        console.log(`  ✓ Label '${labelName}' already exists (ID: ${label.id})`);
        return label;
      }
    }

    // Create label if it doesn't exist
    const mutation = `
      mutation CreateLabel($teamId: String!, $name: String!) {
        issueLabelCreate(input: {teamId: $teamId, name: $name}) {
          success
          issueLabel {
            id
            name
          }
        }
      }
    `;

    const variables = {
      teamId,
      name: labelName,
    };

    const result = await this.query(mutation, variables);
    const label = result.issueLabelCreate.issueLabel;
    console.log(`  ✓ Created label '${labelName}' (ID: ${label.id})`);
    return label;
  }

  async getOrCreateProject(teamId, projectName) {
    // Query for existing projects
    const query = `
      query Projects($teamId: String!) {
        team(id: $teamId) {
          projects {
            nodes {
              id
              name
              url
            }
          }
        }
      }
    `;

    const data = await this.query(query, { teamId });
    const projects = data.team?.projects?.nodes || [];

    for (const project of projects) {
      if (project.name === projectName) {
        console.log(`✓ Project '${projectName}' already exists`);
        console.log(`  ID: ${project.id}`);
        console.log(`  URL: ${project.url}`);
        return project;
      }
    }

    // Create project if it doesn't exist
    const mutation = `
      mutation CreateProject($teamIds: [String!]!, $name: String!) {
        projectCreate(input: {teamIds: $teamIds, name: $name}) {
          success
          project {
            id
            name
            url
          }
        }
      }
    `;

    const variables = {
      teamIds: [teamId],
      name: projectName,
    };

    const result = await this.query(mutation, variables);
    const project = result.projectCreate.project;
    console.log(`✓ Created project '${projectName}'`);
    console.log(`  ID: ${project.id}`);
    console.log(`  URL: ${project.url}`);
    return project;
  }

  async getOrCreateIssue(teamId, projectId, title, labelIds) {
    // Query for existing issues in the project
    const query = `
      query ProjectIssues($projectId: String!) {
        project(id: $projectId) {
          issues {
            nodes {
              id
              title
              url
            }
          }
        }
      }
    `;

    const data = await this.query(query, { projectId });
    const issues = data.project?.issues?.nodes || [];

    for (const issue of issues) {
      if (issue.title === title) {
        console.log(`  ✓ Issue '${title}' already exists`);
        console.log(`    ID: ${issue.id}`);
        console.log(`    URL: ${issue.url}`);
        return issue;
      }
    }

    // Create issue if it doesn't exist
    const mutation = `
      mutation CreateIssue($teamId: String!, $projectId: String!, $title: String!, $labelIds: [String!]!) {
        issueCreate(input: {teamId: $teamId, projectId: $projectId, title: $title, labelIds: $labelIds}) {
          success
          issue {
            id
            title
            url
            identifier
          }
        }
      }
    `;

    const variables = {
      teamId,
      projectId,
      title,
      labelIds,
    };

    const result = await this.query(mutation, variables);
    const issue = result.issueCreate.issue;
    console.log(`  ✓ Created issue '${title}'`);
    console.log(`    ID: ${issue.id}`);
    console.log(`    Identifier: ${issue.identifier}`);
    console.log(`    URL: ${issue.url}`);
    return issue;
  }
}

async function main() {
  // Get API key from environment
  const apiKey = process.env.LINEAR_API_KEY;
  if (!apiKey) {
    console.error('❌ Error: LINEAR_API_KEY environment variable not set');
    process.exit(1);
  }

  console.log('🚀 Linear Bootstrap Script');
  console.log('='.repeat(60));

  const linear = new LinearBootstrap(apiKey);

  // 1. Ensure team exists
  console.log('\n1️⃣  Ensuring team exists...');
  const team = await linear.getOrCreateTeam('Agent-Control-Plane');
  const teamId = team.id;

  // 2. Create labels
  console.log('\n2️⃣  Creating labels...');
  const labelNames = [
    'zone-3a', 'zone-3b', 'zone-3c', 'zone-4a', 'zone-4b',
    'zone-7', 'zone-8', 'zone-10b', 'zone-12', 'zone-13',
  ];

  const labels = {};
  for (const labelName of labelNames) {
    const label = await linear.getOrCreateLabel(teamId, labelName);
    labels[labelName] = label;
  }

  // 3. Create project
  console.log('\n3️⃣  Creating project...');
  const project = await linear.getOrCreateProject(
    teamId,
    'MVP 1 — PT App & Agent Pilot'
  );
  const projectId = project.id;

  // 4. Create issues
  console.log('\n4️⃣  Creating issues...');
  const issuesConfig = [
    {
      title: 'Define Supabase Schema for PT App',
      labels: ['zone-7', 'zone-8'],
    },
    {
      title: 'Scaffold iOS SwiftUI App Structure',
      labels: ['zone-12'],
    },
    {
      title: 'Create PT Agent Service Backend Skeleton',
      labels: ['zone-3c', 'zone-12'],
    },
  ];

  for (const issueConfig of issuesConfig) {
    const labelIds = issueConfig.labels.map(labelName => labels[labelName].id);
    await linear.getOrCreateIssue(teamId, projectId, issueConfig.title, labelIds);
  }

  console.log('\n' + '='.repeat(60));
  console.log('✅ Bootstrap complete!');
}

main().catch(error => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});
