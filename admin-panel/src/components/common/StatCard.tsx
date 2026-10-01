import React from 'react';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: string | React.ReactNode;
  color?: string;
  bgLight?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  label,
  value,
  icon,
  color = '#FF5A5F',
  bgLight = '#FFF0F0',
}) => {
  return (
    <div className="stat-card">
      <div className="stat-icon" style={{ background: bgLight, color: color }}>
        {icon}
      </div>
      <div>
        <div className="stat-val">{value}</div>
        <div className="stat-lbl">{label}</div>
      </div>
    </div>
  );
};
