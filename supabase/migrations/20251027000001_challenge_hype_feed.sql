-- =====================================================
-- Challenge Hype Feed Schema
-- Milestone 3: Verified Trainer Challenges Setup
-- Created: October 27, 2025
-- Description: Community posts, reactions, and winner announcements for challenges
-- =====================================================

-- =====================================================
-- CHALLENGE POSTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS challenge_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_type TEXT NOT NULL DEFAULT 'post', -- 'post', 'cheer', 'progress'
  content TEXT NOT NULL,
  image_url TEXT, -- Optional image attachment
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX idx_challenge_posts_challenge_id ON challenge_posts(challenge_id);
CREATE INDEX idx_challenge_posts_user_id ON challenge_posts(user_id);
CREATE INDEX idx_challenge_posts_created_at ON challenge_posts(created_at DESC);

-- =====================================================
-- CHALLENGE POST REACTIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS challenge_post_reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES challenge_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL, -- 'fire', 'muscle', 'heart', 'clap', 'wow'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id, reaction_type) -- One reaction type per user per post
);

-- Index for faster queries
CREATE INDEX idx_post_reactions_post_id ON challenge_post_reactions(post_id);
CREATE INDEX idx_post_reactions_user_id ON challenge_post_reactions(user_id);

-- =====================================================
-- UPDATE CHALLENGES TABLE (Add winner fields)
-- =====================================================

ALTER TABLE challenges
ADD COLUMN IF NOT EXISTS winner_announced_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS winner_data JSONB; -- Stores winner information (top 3, points, etc.)

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE challenge_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_post_reactions ENABLE ROW LEVEL SECURITY;

-- Challenge Posts Policies
-- Users can view posts from challenges they've joined
CREATE POLICY "Users can view challenge posts"
  ON challenge_posts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM challenge_participants
      WHERE challenge_participants.challenge_id = challenge_posts.challenge_id
      AND challenge_participants.user_id = auth.uid()
    )
    OR
    -- Or if challenge is public
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_posts.challenge_id
      AND challenges.privacy = 'public'
    )
  );

-- Users can create posts in challenges they've joined
CREATE POLICY "Users can create challenge posts"
  ON challenge_posts FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND
    EXISTS (
      SELECT 1 FROM challenge_participants
      WHERE challenge_participants.challenge_id = challenge_posts.challenge_id
      AND challenge_participants.user_id = auth.uid()
    )
  );

-- Users can update their own posts
CREATE POLICY "Users can update own posts"
  ON challenge_posts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own posts
CREATE POLICY "Users can delete own posts"
  ON challenge_posts FOR DELETE
  USING (auth.uid() = user_id);

-- Challenge Post Reactions Policies
-- Users can view all reactions
CREATE POLICY "Users can view reactions"
  ON challenge_post_reactions FOR SELECT
  USING (true);

-- Users can add reactions to posts they can see
CREATE POLICY "Users can add reactions"
  ON challenge_post_reactions FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND
    EXISTS (
      SELECT 1 FROM challenge_posts
      WHERE challenge_posts.id = challenge_post_reactions.post_id
    )
  );

-- Users can delete their own reactions
CREATE POLICY "Users can delete own reactions"
  ON challenge_post_reactions FOR DELETE
  USING (auth.uid() = user_id);

-- Admin override policies
CREATE POLICY "Admins can manage all posts"
  ON challenge_posts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can manage all reactions"
  ON challenge_post_reactions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_challenge_post_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER challenge_post_updated_at
  BEFORE UPDATE ON challenge_posts
  FOR EACH ROW
  EXECUTE FUNCTION update_challenge_post_timestamp();

-- Function to get post reaction counts
CREATE OR REPLACE FUNCTION get_post_reaction_counts(p_post_id UUID)
RETURNS TABLE(
  reaction_type TEXT,
  count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    challenge_post_reactions.reaction_type,
    COUNT(*) as count
  FROM challenge_post_reactions
  WHERE post_id = p_post_id
  GROUP BY challenge_post_reactions.reaction_type;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Insert sample post types enum (for reference)
COMMENT ON COLUMN challenge_posts.post_type IS
  'Post type: post (general update), cheer (encouragement), progress (workout achievement)';

COMMENT ON COLUMN challenge_post_reactions.reaction_type IS
  'Reaction emoji: fire 🔥, muscle 💪, heart ❤️, clap 👏, wow 😲';

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON challenge_posts TO authenticated;
GRANT SELECT, INSERT, DELETE ON challenge_post_reactions TO authenticated;

-- =====================================================
-- REALTIME SUBSCRIPTIONS
-- =====================================================

-- Enable realtime for challenge posts (for live feed updates)
ALTER PUBLICATION supabase_realtime ADD TABLE challenge_posts;
ALTER PUBLICATION supabase_realtime ADD TABLE challenge_post_reactions;

-- =====================================================
-- END OF MIGRATION
-- =====================================================
